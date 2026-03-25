#🚀 Deploy Static Application on Amazon EKS with ALB Ingress
##📌 Project Overview

--> This project demonstrates how to:

--> Create an EKS cluster using eksctl

--> Deploy a static NGINX application

--> Expose it using AWS ALB Ingress Controller

--> Troubleshoot real-world issues

#🧰 Tech Stack

##AWS EKS

--> Kubernetes (kubectl)

--> eksctl

--> Helm

--> AWS Load Balancer Controller

--> NGINX

#🏗️ Architecture
```
User → ALB (Ingress) → Service (ClusterIP) → Pods (NGINX)
```

#⚙️ Setup Instructions

##1️⃣ Create EKS Cluster
```
eksctl create cluster \
  --name test-cluster \
  --region ap-south-1 \
  --nodegroup-name test-nodes \
  --node-type t3.medium \
  --nodes 2
  ```

##2️⃣ Configure kubectl
```
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name test-cluster

  ```

##3️⃣ Deploy Application

kubectl create deployment nginx --image=nginx

##4️⃣ Create Service
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      ```
kubectl apply -f service.yaml

#🌐 Setup ALB Ingress
##5️⃣ Enable OIDC
```
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster test-cluster \
  --approve
  ```

##6️⃣ Create IAM Policy
```
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

⚠️ If already exists, reuse it.

##7️⃣ Create IAM Service Account (IRSA)
```
eksctl create iamserviceaccount \
  --cluster=test-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
  ```
##8️⃣ Install ALB Controller
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=test-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
  ```
##9️⃣ Create Ingress
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```
kubectl apply -f ingress.yaml

#🔍 Access Application
```
kubectl get ingress
```
👉 Open the ADDRESS in browser

🐞 Troubleshooting Guide
❌ Helm not installed
zsh: command not found: helm

✅ Fix:
```
brew install helm
```
❌ IAM Policy Already Exists
EntityAlreadyExists

✅ Fix:

Reuse existing policy ARN

❌ Wrong IAM ARN
Unauthorized

✅ Fix:

arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy
❌ ServiceAccount exists
excluded

✅ Fix:

--override-existing-serviceaccounts
❌ ALB Controller CrashLoopBackOff

👉 Cause:

IAM not attached properly

✅ Fix:

Recreate IAM service account

Restart deployment

❌ Ingress ADDRESS empty

👉 Cause:

Missing ingress class or annotations

✅ Fix:

ingressClassName: alb
❌ kubectl authentication error
the server has asked for credentials

✅ Fix:
```
aws eks update-kubeconfig --region ap-south-1 --name test-cluster
```
❌ DNS not resolving
DNS_PROBE_POSSIBLE

✅ Fix:

Wait 2–5 minutes (ALB provisioning)

🧠 Key Learnings

eksctl uses CloudFormation internally

Ingress requires AWS Load Balancer Controller

IRSA (IAM Roles for Service Accounts) is critical

Ingress reduces cost by using single ALB

#💸 Cleanup
```
eksctl delete cluster \
  --name test-cluster \
  --region ap-south-1
  ```
🎯 Outcome

✔ EKS cluster deployed
✔ Application exposed via ALB
✔ Real-world debugging experience gained

🚀 Future Improvements

HTTPS using ACM

Domain-based routing

CI/CD integration

Terraform automation