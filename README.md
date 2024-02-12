Download eksctl - https://github.com/eksctl-io/eksctl
# To create cluster
eksctl create cluster \\\
--name cluster-name \\\
--version 1.29 \\\
--region us-east-1 \\\
--nodegroup-name linux-nodes \\\
--node-type t2.micro \\\
--nodes 2

# To delete cluster
eksctl delete cluster --name cluster-name

# Troubleshoot cluster
Proceed to cloudformation to review

# Troubleshoot Persistent Volume for MongoDB
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.27"

# Create IAM EC2 Policy that is attached to eks
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
           
                "ec2:CreateVolume",
                "ec2:CreateTags",
                "ec2:AttachVolume",
                "ec2:DescribeVolumes"
            ],
            "Resource": "*"
        }
    ]
}

https://platform9.com/learn/v1.0/tutorials/nginix-controller-via-yaml
Step 1 - Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
