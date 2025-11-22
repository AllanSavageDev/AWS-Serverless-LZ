# AWS Serverless Landing Zone  
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Live Demo  
Visit: https://aws-serverless.net

## What is this?  
This repository contains a **live, fully-deployed AWS serverless environment**, built with Terraform and running real APIs, a static front-end, multiple domains, and global content delivery via CloudFront.  

It was built as a *portfolio demonstration* — not a production product — to show my ability to design, deploy, and operate cloud-native infrastructure end-to-end.



## Key Highlights  
- **Infrastructure as Code**: Entire stack managed via Terraform — VPC, subnets, NAT/IGW, private routing, security groups, IAM roles, KMS, Secrets Manager.  
- **Serverless Backend**: AWS Lambda functions running in private subnets behind APIs, integrating with RDS PostgreSQL and DynamoDB.  
- **Global Delivery**: S3-hosted static front-end routed through CloudFront, custom domains, HTTPS, cache invalidation.  
- **Multi-Domain Configuration**: Two domains (`aws-serverless.net` and `lingua1.com`) wired into the same architecture.  
- **CI/CD Ready**: GitHub Actions with OIDC based role assumption, Terraform CLI, packaging Lambdas, infrastructure deployment automation.

## Architecture Overview  
![](docs/architecture-diagram.svg)  
*A diagram showing the VPC, Lambda, API Gateway, CloudFront, and DNS flows.*

## Project Structure  

```text
.
├── envs/
│ └── dev/ # environment configuration
├── modules/ # Terraform modules
│ ├── api-log/
│ ├── api-notify/
│ ├── api-queue/
│ ├── api-rds/
│ ├── api-todo/
│ ├── api-weather/
│ ├── sys-bastion/
│ ├── sys-dynamodb/
│ ├── sys-lambda/
│ ├── sys-rds/
│ ├── sys-route53/
│ ├── sys-security/
│ ├── sys-vpc/
│ ├── sys-vpce/
│ └── sys-www/
├── scripts/
│ ├── api-log/
│ ├── api-notify/
│ ├── api-queue/
│ ├── api-rds/
│ ├── api-todo/
│ └── api-weather/
├── www/
│ └── demo/
├── .gitignore
├── README.md
```

## Explore It Yourself  
1. Clone the repo: `git clone git@github.com:AllanSavageDev/AWS-Serverless-LZ.git`  
2. Review the `/modules/` folder to see how each AWS service is defined  
3. Browse the `www/demo/dash/` directory and open the site URL  
4. Inspect the live AWS account (public endpoints) powered by this code  

> **Note**: This code deploys real, live resources. Because this is a portfolio demo, some components include shortcuts and simplified modules. It is *not* intended as a production-grade, ready-to-run template. It’s designed to illustrate the full end-to-end workflow and cloud ecosystem.

## About Me  
**Allan Savage** — Cloud & DevOps Engineer specializing in AWS, Terraform, Serverless architecture.  
GitHub: [@AllanSavageDev](https://github.com/AllanSavageDev)  
LinkedIn: [linkedin.com/in/allansavage](https://linkedin.com/in/allansavage)  

## License  
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
