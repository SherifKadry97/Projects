# 🌩️ AWS Highly Available and Scalable Web Infrastructure with Terraform
A Terraform project that deploys a highly available and scalable web application infrastructure on AWS with best practices for security, scalability, and high availability. It’s designed to demonstrate real-world **DevOps and Cloud Infrastructure automation** — including **networking, compute scaling, and load balancing** — built from scratch as infrastructure-as-code.

📋 Project Overview

This Terraform configuration creates a complete web application infrastructure featuring:
    VPC Architecture: Multi-AZ VPC with public and private subnets
    High Availability: Distributed across two availability zones
    Security: Proper network segmentation and security groups
    Auto Scaling: Automated scaling of web servers based on demand
    Load Balancing: Application Load Balancer for traffic distribution
    NAT Gateway: Secure outbound internet access for private instances
 
🛠️ Technologies Used
    Terraform: Infrastructure as Code
    AWS Services:
        VPC & Networking (Subnets, Route Tables, IGW, NAT Gateway)
        EC2 Auto Scaling Groups
        Application Load Balancer
        Security Groups
        Launch Templates
        Elastic IPs

📁 Project Structure
terraform-aws-vpc-asg/
├── main.tf                 # Main infrastructure configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values (create from example)
├── terraform.tfvars.example # Example variables file
└── README.md              # This file


![Architecture Diagram](./terraform-aws-2tier-diagram.png)

