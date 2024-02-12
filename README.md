Download eksctl - https://github.com/eksctl-io/eksctl
# To create cluster
eksctl create cluster \\

--name cluster-name \\\
--version 1.17 \\
--region us-east-1 \\
--nodegroup-name linux-nodes \\
--node-type t2.micro \\
--node 2

# To delete cluster
eksctl delete cluster --name cluster-name

https://platform9.com/learn/v1.0/tutorials/nginix-controller-via-yaml
Step 1 - Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
