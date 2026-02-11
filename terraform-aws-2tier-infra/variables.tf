variable "aws_region" {
  description = "AWS region to deploy resources in"
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = map(string)
  default = {
    public_a = "10.0.1.0/24"
    public_b = "10.0.2.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = map(string)
  default = {
    private_a = "10.0.3.0/24"
    private_b = "10.0.4.0/24"
  }
}

variable "azs" {
  description = "Availability zones for the subnets"
  type        = map(string)
  default = {
    public_a  = "us-east-1a"
    public_b  = "us-east-1b"
    private_a = "us-east-1a"
    private_b = "us-east-1b"
  }
}

variable "instance_type" {
  description = "EC2 instance type for ASG"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-052064a798f08f0d3"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}
