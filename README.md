# 🌐 🔶 Architecture Diagram — GitHub OIDC → AWS STS → Terraform
```
                 ┌────────────────────────────────────────┐
                 │          GitHub Actions Runner         │
                 │      (Ubuntu VM executing workflow)    │
                 └────────────────────────────────────────┘
                                 │
                                 │ 1. Request OIDC Token
                                 ▼
                   ┌──────────────────────────────────────┐
                   │  GitHub OIDC Provider (JWT Issuer)   │
                   │  https://token.actions.githubusercontent.com │
                   └──────────────────────────────────────┘
                                 │
                                 │ 2. GitHub returns signed JWT
                                 ▼
       ┌────────────────────────────────────────────────────────────────┐
       │                 GitHub Runner receives JWT Token               │
       │     (Contains: repo, branch, workflow, commit, audience)      │
       └────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 3. Send JWT to AWS STS to assume role
                                 ▼
             ┌──────────────────────────────────────────────────┐
             │            AWS STS (Security Token Service)      │
             │        sts.amazonaws.com                          │
             └──────────────────────────────────────────────────┘
                                 │
                     ┌───────────────────────────────────────┐
                     │ 4. STS Validates the Token:           │
                     │   ✔ Signature from GitHub             │
                     │   ✔ Audience == sts.amazonaws.com     │
                     │   ✔ IAM Role Trust Policy matches     │
                     └───────────────────────────────────────┘
                                 │
                                 │ 5. If valid → STS returns
                                 │    temporary AWS credentials
                                 ▼
              ┌────────────────────────────────────────────────────────────────┐
              │  GitHub Runner receives AWS Temporary Credentials               │
              │     • AWS_ACCESS_KEY_ID                                         │
              │     • AWS_SECRET_ACCESS_KEY                                     │
              │     • AWS_SESSION_TOKEN                                         │
              │  (Valid for 1 hour)                                             │
              └────────────────────────────────────────────────────────────────┘
                                 │
                                 │ 6. Terraform uses these env variables
                                 ▼
          ┌──────────────────────────────────────────────────────────┐
          │                      Terraform CLI                       │
          │ terraform init / plan / apply                            │
          │ AWS provider reads credentials from environment variables │
          └──────────────────────────────────────────────────────────┘
                                 │
                                 │ 7. Terraform interacts with AWS
                                 ▼
       ┌────────────────────────────────────────────────────────────────┐
       │                   AWS Services (Your Infrastructure)           │
       │       Example: Route53, VPC, EC2, RDS, S3, Lambda, IAM…        │
       └────────────────────────────────────────────────────────────────┘

```
# 1️⃣ The GitHub Actions Runner starts

Your workflow begins on a fresh Ubuntu virtual machine provided by GitHub.<br>
This runner needs a way to authenticate to AWS — without storing access keys.

# 2️⃣ Runner Requests an OIDC Token from GitHub

Your workflow calls the GitHub OIDC provider.
GitHub issues a signed JWT token that contains:
```
==>Repository name
==>Branch name
==>Workflow name
==>Commit SHA
==>Audience = sts.amazonaws.com
```
# 3️⃣ JWT Token is Delivered to AWS STS

Your workflow sends the token to:

==>AWS Security Token Service (STS)

STS is responsible for issuing temporary AWS credentials.<br>
This proves the workflow is trusted and coming from your exact repository.

# 4️⃣ AWS STS Verifies the JWT

AWS checks:
✔ The signature<br>
Must match GitHub’s OIDC signing key.<br>
✔ The audience<br>
Token must be intended for AWS STS:
```
"aud": "sts.amazonaws.com"

```
✔ The IAM Role Trust Policy
Your IAM role must allow GitHub OIDC access, like:
```
"Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
```
And conditions such as repo & branch restrictions.<br>
If ANYTHING is wrong → AWS rejects the request.

# 5️⃣ AWS Returns Temporary Credentials

If the token is valid, AWS STS gives:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```
⏳ Valid for 1 hour only <br>
🔒 Scoped to your IAM role permissions<br>
💡 Never stored anywhere<br>
These credentials are put into the runner’s environment variables.

# 6️⃣ Terraform Uses the Credentials
Terraform now executes:
```
terraform init
terraform plan
terraform apply

```
The AWS provider reads the temporary credentials automatically from environment variables:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN

```
# 7️⃣ Terraform Applies Infrastructure to AWS
Terraform uses the credentials to modify real AWS resources in:
=>Route53
=>VPC
=>EC2
=>RDS
=>IAM
=>S3
=>CloudFront
Anything supported by AWS provider

# 🟢 Final Takeaway
OIDC = Secure, passwordless AWS access for GitHub Actions.
✔ No static secrets
✔ Repo + branch restricted
✔ Temporary credentials
✔ Strongly verified identity
✔ Recommended by AWS + GitHub
-------------------------------------------------------------------------------------------------------------------------------------------

Here is the exact flow in simple terms:

✅ When is the OIDC token created?
GitHub creates the OIDC token dynamically during a GitHub Actions job, NOT before.
✔️ Only during the job
When your workflow reaches this step:
```
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v2

```
GitHub automatically issues a temporary OIDC ID token for that specific job execution.

✔️ Token exists for a few seconds only

It is short-lived (usually valid for < 5 minutes)
It cannot be reused in another workflow run
It is different for every job

Why?
```
GitHub acts as an identity provider (IDP).
AWS acts as a relying party.
To prevent abuse:
Tokens are created only when needed
Tokens are not stored
Tokens are rotated automatically
Each token is tied to:
repo
workflow name
job ID
commit SHA
environment
```

🔐 How AWS uses the token
When the configure-aws-credentials step runs:
GitHub requests an OIDC token for the current job
GitHub sends it to AWS STS (via the action)
AWS verifies:
Issuer = token.actions.githubusercontent.com
Audience (aud) = AWS
Repo matches trust policy
AWS returns temporary IAM credentials
(valid for 15 minutes)

🚀 This means:
❌ No long-term AWS credentials stored in GitHub
✔️ Temporary AWS credentials only when job runs
✔️ Auto-rotated, auto-expired
✔️ You are safe even if someone leaks logs


📌 Example Timeline
1️⃣ Job starts → No token yet
2️⃣ configure-aws-credentials runs → Token created
3️⃣ AWS validates → Returns temporary IAM Role credentials
4️⃣ Terraform commands run using those short-lived credentials
5️⃣ Job ends → Token expires, credentials deleted

######## IMPORTANT #############

💡 So what actually happens to the credentials?
## Phase: What happens
```During workflow	Temporary STS keys exist in memory
   After workflow step	Keys removed from environment
   After workflow completes	Runner VM is destroyed
   After 15 minutes	AWS expires STS credentials
   ✔ Nothing persists
   ✔ Nothing to delete manually
   ✔ Impossible for credentials to leak after workflow ends
```
# 📌 Security Benefit:
```
   Because credentials are short-lived:
   Even a compromised runner cannot reuse credentials
   No need for AWS Access Keys stored in GitHub
   No long-lived secrets to rotate
   Strong trust boundary enforced by IAM Trust Policy
```

# IAM ROLE SET_UP

Below is a clear, beginner-friendly, step-by-step procedure to create the IAM Role for GitHub Actions OIDC and attach it properly so Terraform can assume it.<br>
✅ Step 1 — Enable OIDC Provider in IAM
1. Go to AWS Console → IAM
2. In the left menu, click Identity providers
3. Click Add provider
4. Fill in:

| Field         | Value                                         |
| ------------- | --------------------------------------------- |
| Provider type | **OpenID Connect**                            |
| Provider URL  | `https://token.actions.githubusercontent.com` |
| Audience      | `sts.amazonaws.com`                           |

5. Click Add provider
   ➡️ Now AWS trusts GitHub as an identity provider.

✅ Step 2 — Create the IAM Role for GitHub OIDC to Assume
Go to AWS → IAM → Roles
Click Create Role
Role type:
Web Identity → GitHub OIDC Provider
(Select the provider you created earlier)
Audience:
sts.amazonaws.com
Click Next

✅ Step 3 — Add Permission Policies to the Role
This depends on what Terraform will manage.
Example: Basic permissions for Route53, EC2, S3, VPC, etc:
✔️ For a typical Terraform admin role:
```
AmazonEC2FullAccess
AmazonS3FullAccess
AmazonVPCFullAccess
AmazonRoute53FullAccess
```
IAMFullAccess (if Terraform creates IAM roles)
Or attach your own custom policy
⚠️ Best practice: create a custom least-privilege policy instead of full access.
Click Next

✅ Step 4 — Add Trust Policy Conditions (IMPORTANT)
Before creating the role, you must add conditions to restrict GitHub access.
Replace <YOUR_AWS_ACCOUNT_ID>, <YOUR_GITHUB_USER_OR_ORG> and <YOUR_REPO>.
Trust Policy (final version):

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_USER_OR_ORG>/<YOUR_REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}

```

Explanation:
| Condition                                 | Meaning                                               |
| ----------------------------------------- | ----------------------------------------------------- |
| `aud = sts.amazonaws.com`                 | OIDC token is meant for AWS                           |
| `sub = repo:ORG/REPO:ref:refs/heads/main` | Only **main branch** of this repo can assume the role |

Click Create Role

✅ Step 5 — Use the Role in GitHub Actions
In your GitHub workflow:
```
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/<YOUR_ROLE_NAME>
    aws-region: ap-south-1

```
➡️ When this step runs, GitHub issues a temporary OIDC token
➡️ AWS STS validates and returns temporary credentials
➡️ Terraform now has access

✅ Step 6 — No Secrets Needed
You do NOT put AWS Access/Secret keys in GitHub.
OIDC replaces static credentials completely.

# 📌 Where is the IAM Role attached?
There is no EC2 instance, no user, no group attached.
The role is attached ONLY to:
✔ The GitHub OIDC Identity Provider (IdP)
✔ Permissions policies you added
✔ GitHub workflow via role-to-assume
AWS STS creates temporary credentials only at runtime. 
