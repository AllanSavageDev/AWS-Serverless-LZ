# Terraform-AWS-Full-Landing-Zone

### Overview
This repository contains a complete, production-grade AWS Landing Zone built entirely with Terraform.  
It demonstrates real-world patterns for secure, serverless infrastructure — the same design used by top-tier cloud consulting shops.

---

### 🧱 Core Stack

| Layer | Components | Description |
|-------|-------------|--------------|
| **Network (VPC)** | Custom VPC, public + private subnets, route tables, NAT + IGW | Isolated network foundation for all workloads |
| **Compute** | AWS Lambda (Python 3.11) | Serverless backend functions running inside private subnets |
| **Data** | RDS PostgreSQL (private) + DynamoDB (public-edge use) | Relational and NoSQL data layers, both privately routed |
| **Security** | IAM, KMS, Secrets Manager, dedicated SGs per endpoint | Principle of least privilege enforced at every layer |
| **Edge** | API Gateway + CloudFront + S3 static hosting | Global CDN + REST API surface for web and API clients |
| **Automation** | GitHub Actions + Terraform CLI | One-command deploy via OIDC-based CI/CD pipeline |

---

### 🚀 Highlights

- **Private-only architecture:** All data and APIs live in private subnets, accessed through VPC endpoints.  
- **Per-service security groups:** Each interface endpoint and Lambda function has its own SG for fine-grained control.  
- **Secrets handled properly:** DB credentials stored in AWS Secrets Manager and fetched by Lambdas at runtime.  
- **API Gateway routing:** Multiple Lambda integrations (`/api-now`, `/api-rds`, `/api-notify`) wired through HTTP API.  
- **CloudFront static front-end:** Minimal HTML dashboard to exercise live APIs and visualize responses.  

---

### 🧩 Structure

envs/
dev/
main.tf # Core environment stack
modules/
sys-vpc/ # VPC + networking
rds/ # PostgreSQL database
lambda-api/ # Lambda + API Gateway integration
bastion/ # SSH/Session Manager host
scripts/
api-rds/ # Lambda source (Python)
api-notify/
api-now/


---

### ⚙️ Deploy

```bash
terraform init
terraform plan
terraform apply
```


Terraform builds the entire environment — network, endpoints, Lambdas, and database — from scratch.

🧠 Tech Focus

Terraform: Infrastructure-as-Code, module design, remote state best practices

AWS: VPC, Lambda, API Gateway, RDS, DynamoDB, CloudFront, S3, Secrets Manager

Python: Lightweight Lambda handlers (psycopg2/pg8000, boto3)

CI/CD: GitHub Actions with OIDC authentication and Makefile-based Lambda packaging

📚 Use This Repo To

Study a full AWS Landing Zone reference written 100% in Terraform.

See how private-only Lambda + RDS architectures are wired up cleanly.

Fork and adapt for your own consulting or certification projects.

Author: Allan Savage
License: MIT


