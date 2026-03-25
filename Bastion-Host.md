#📝 AWS Jump Host (Bastion) Setup – Notes


##👉 Jump Host (Bastion Host)

A public EC2 instance used to access private EC2 instances
Acts as a secure bridge
```
Laptop → Bastion (Public) → Private EC2
```
##🌐 2. Architecture
```
VPC → 10.0.0.0/16
Public Subnet → 10.0.1.0/24 (Bastion)
Private Subnet → 10.0.2.0/24 (App Server)
```

##🚀 3. EC2 Setup

🟢 Bastion Host
Subnet → Public
Public IP → Enabled
Key → bastion.pem

##Security Group:

SSH (22) → Your IP
🔵 Private EC2 (App Server)
Subnet → Private
Public IP → Disabled
Key → app-server.pem

##Security Group:

SSH (22) → Bastion Security Group
🔗 4. Connection Steps
Step 1: Connect to Bastion
```
ssh -i bastion.pem ec2-user@<bastion-public-ip>
```
Step 2: Connect to Private EC2 (from bastion)


#Option A: Copy key (simple)
```
scp -i bastion.pem app-server.pem ec2-user@<bastion-ip>:/home/ec2-user/

ssh -i bastion.pem ec2-user@<bastion-ip>

chmod 400 app-server.pem

ssh -i app-server.pem ec2-user@<private-ip>

```

#Option B: SSH Agent (Best Practice ✅)

On local:
```
eval "$(ssh-agent -s)"
ssh-add app-server.pem
```
##Connect:
```
ssh -A -i bastion.pem ec2-user@<bastion-ip>
```

##From bastion:
```
ssh ec2-user@<private-ip>
```
##🔥 5. One Command SSH (Advanced)
```
ssh -i bastion.pem -o ProxyCommand="ssh -W %h:%p ec2-user@<bastion-ip>" ec2-user@<private-ip>
```

##🔐 6. Permissions (IMPORTANT)
```
chmod 400 bastion.pem
chmod 400 app-server.pem
```
##⚠️ 7. Common Errors
❌ File not found
Identity file not accessible

👉 Fix:

Check path (ls)
Use full path
❌ Permission denied
Permission denied (publickey)

👉 Fix:

Correct key
Correct username
Correct permissions
❌ Cannot connect to private IP

👉 Reason:

Private IP not accessible from internet

👉 Fix:

Use bastion host
🧠 8. Key Points
Never expose private EC2 to internet ❗
Bastion is the only entry point
Use SSH Agent for better security
Restrict SSH to your IP
🛡️ 9. Better Alternative (Modern AWS)

👉 Use AWS Systems Manager Session Manager

No SSH
No PEM keys
No bastion required
⚖️ 10. Summary
Component	Purpose
Bastion Host	Entry point
Private EC2	Application
PEM Keys	Authentication
SSH Agent	Secure key usage
🚀 Final One-Line Summary

👉
A bastion host is a public EC2 instance used to securely access private EC2 instances via SSH, acting as a controlled gateway.

If you want, I can also give you:

✅ Terraform version of this setup
✅ Diagram for interview explanation
✅ Session Manager setup (no SSH at all)
