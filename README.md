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
