# 🌩️ AWS Highly Available and Scalable 2-tier Web Infrastructure with Terraform
A **Terraform project** that deploys a **highly available and scalable web application infrastructure on AWS** with best practices for security, scalability, and high availability. It’s designed to demonstrate real-world **DevOps and Cloud Infrastructure automation** — including **networking, compute scaling, and load balancing** — built from scratch as infrastructure-as-code.

---

## 🏗️ Architecture Diagram

![AWS Architecture Diagram](./terraform-aws-2tier-diagram.png)

> *The architecture includes multi-AZ, public/private subnets, Application load balancer, NAT GW, and ASG EC2 instances.*

---

## 📋 Project Overview
This Terraform configuration sets up a complete **two-tier web application infrastructure** with:

- **VPC Architecture** — Multi-AZ VPC with public & private subnets
- **High Availability** — Resources spread across two availability zones  
- **Security** — Segregated network layers with security groups and least privilege  
- **Auto Scaling** — EC2 instances automatically scale based on demand  
- **Load Balancing** — Application Load Balancer (ALB) distributes traffic  
- **NAT Gateway** — Provides secure outbound internet access for private subnets  

---

## 🛠️ Technologies Used

### 🔹 Infrastructure as Code
- **Terraform** — Declarative infrastructure management

### 🔹 AWS Services
- **VPC & Networking:** Subnets, Route Tables, Internet Gateway, NAT Gateway  
- **Compute:** EC2 Instances via Launch Templates  
- **Scaling:** Auto Scaling Groups (min=2, max=4, desired=2)  
- **Load Balancing:** Application Load Balancer (ALB)  
- **Security:** Security Groups, Elastic IPs 
 
---

## 📁 Project Structure
```bash
terraform-aws-2tier-infra/
├── main.tf # Main infrastructure configuration
├── variables.tf # Variable definitions
├── outputs.tf # Output values
└── README.md # Project documentation

```

---

## 🚀 Deployment Instructions

1. **Export AWS Secret and Access keys**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```
3. **Validate Configuration**
   ```bash
   terraform validate
   ```
4. **Preview Changes**
   ```bash
   terraform plan
   ```
5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```
