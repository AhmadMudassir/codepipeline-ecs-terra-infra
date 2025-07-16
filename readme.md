# 🚀 AWS ECS EC2 Launch Type CI/CD Pipeline with Terraform

This repository contains Infrastructure as Code (IaC) using Terraform to provision an **end-to-end AWS ECS cluster (EC2 launch type)** with an Application Load Balancer (ALB) and a **complete CI/CD pipeline** using AWS CodePipeline, CodeBuild, and CodeDeploy for blue/green deployments.

---

## 📦 Features

- 🛡 VPC with public subnets
- 🌐 Internet Gateway and route tables
- 🔒 Security group for HTTP and SSH access
- ⚙️ ECS cluster (EC2 launch type) with Auto Scaling Group and Launch Template
- 🎯 Application Load Balancer (ALB) forwarding traffic to ECS tasks
- 🐳 ECS Service with Task Definition for a demo Node.js container
- 💚 Blue/Green deployments via AWS CodeDeploy
- 🔑 IAM roles and policies for ECS, EC2, CodeBuild, CodePipeline, and CodeDeploy
- 🛠 CI/CD pipeline using AWS CodePipeline + CodeBuild:
  - 📥 Pulls source from GitHub
  - 🏗 Builds and pushes Docker image to Amazon ECR
  - 🚀 Deploys to ECS using CodeDeploy

---

## 🖼 Architecture Diagram

```
GitHub (Source)
    |
    v
AWS CodePipeline
    | -> AWS CodeBuild -> Amazon ECR (Docker Image)
    v
AWS CodeDeploy (Blue/Green)
    |
    v
ECS Service (EC2 Launch Type)
    |
    v
Application Load Balancer
```

<img width="1141" height="561" alt="CodePipeline-ecs-infra-dark" src="https://github.com/user-attachments/assets/b0ffb055-6eb3-4f13-9547-7f41e722a9a7" />


---

## ✅ Prerequisites

- Terraform installed
- AWS CLI configured
- AWS account permissions for:
  - VPC, Subnets, IGW, Route Tables
  - EC2, Security Groups
  - IAM Roles/Policies
  - ECS Cluster/Service
  - ALB, ECR, CodePipeline, CodeBuild, CodeDeploy
- GitHub repository with:
  - Dockerfile
  - buildspec.yml
  - appspec.yml
  - index.js

---

## ⚡ Getting Started

```bash
# 1️⃣ Clone this repository
git clone https://github.com/AhmadMudassir/codepipeline-ecs-terra-infra.git
cd YOUR-REPO

# 2️⃣ Initialize Terraform
terraform init

# 3️⃣ Review and set variables
terraform plan

# 4️⃣ Apply the deployment
terraform apply
```

---

## 📝 Notes

- **Blue/Green Deployments** are fully automated with AWS CodeDeploy.
- **CodePipeline** connects to your GitHub repo, builds Docker images with CodeBuild, pushes to ECR, and triggers ECS deployments.
- All resources and permissions are defined in Terraform for consistent, repeatable infrastructure provisioning.

---
