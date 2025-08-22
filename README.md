# Terraform-EC2-with-Load-Balancer-on-VPC
This project provisions a **highly available infrastructure on AWS** using Terraform.  
It creates the following resources:

VPC** with CIDR block `10.0.0.0/16`
Public Subnet** (for EC2 + ALB)
Private Subnet** (reserved for backend/DB, extendable)
Internet Gateway & Route Tables**
EC2 Instance** (Amazon Linux 2 with Apache Web Server)
Application Load Balancer (ALB)** forwarding traffic to EC2
Security Groups** for controlled access (HTTP/SSH)

---------------------------------------------------------------------------------------------------
## 🚀 Architecture

```text
                Internet
                   │
            ┌──────▼──────┐
            │   AWS ALB   │
            └──────┬──────┘
                   │
            ┌──────▼──────┐
            │   EC2 Web   │
            │   Server    │
            └─────────────┘
                   │
            ┌──────▼──────┐
            │   Private   │
            │   Subnet    │ (future DB/NAT)
            └─────────────┘

------------------------------------------------------------------------------------------------------------------

📂 Project Structure
terraform-aws-vpc-ec2-alb/
│── main.tf        # VPC, EC2, ALB resources
│── variables.tf   # Input variables
│── outputs.tf     # Outputs (ALB DNS, etc.)
│── provider.tf    # AWS provider
│── README.md      # Documentation













