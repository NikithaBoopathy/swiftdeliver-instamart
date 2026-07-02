# Instamart: Highly Available 3-Tier Enterprise DevSecOps Architecture

## Project Overview
Instamart is a production-grade, highly available, and secure 3-tier e-commerce application platform deployed on AWS. This project documents the complete architectural transformation from a monolithic single-server baseline to an elastic, self-healing, multi-AZ containerized ecosystem governed by Infrastructure as Code (IaC) and Configuration as Code (CaC). 

The goal of this project is to implement an automated, end-to-end DevSecOps CI/CD pipeline that enforces Shift-Left security, zero-downtime deployments, and strict network isolation.

---

## Architecture

### Infrastructure Design
* **Edge Routing:** Public subnets house an **AWS Application Load Balancer (ALB)** acting as the exclusive ingress point.
* **Static Asset Delivery:** The **React/Vite Frontend** application is decoupled into an independent static build bucket hosted via **Amazon S3**.
* **Compute Tier (EKS):** The **Spring Boot Backend Engine** runs as highly available Kubernetes Pods within an Amazon EKS cluster, isolated in Private Subnets.
* **Data Tier:** An **Amazon RDS PostgreSQL** cluster resides in an isolated Data Subnet Group, accessible only via stateful Security Group rules originating from the compute tier.

### Diagram

```mermaid
flowchart TB
    User((Web User))

    subgraph AWS [AWS Cloud Infrastructure]
        
        subgraph S3 [Amazon S3 - Edge]
            Frontend["React/Vite Frontend<br>(Static Website)"]
        end

        subgraph VPC [Custom VPC - Isolated Network]
            
            subgraph Public [Public Subnet]
                ALB["Application Load Balancer<br>(Ingress)"]
            end

            subgraph PrivateCompute [Private Subnet - Compute]
                Backend["Spring Boot Backend<br>(Amazon EKS Node Group)"]
            end

            subgraph PrivateData [Private Subnet - Data]
                Database[("Amazon RDS<br>(PostgreSQL)")]
            end
        end
        
        subgraph CI [DevSecOps Pipeline]
            ECR{"Amazon ECR<br>(Container Registry)"}
        end
    end

    User == "1. Fetch UI" ==> Frontend
    User == "2. API Requests" ==> ALB
    ALB == "3. Route Traffic" ==> Backend
    Backend == "4. Read/Write Data" ==> Database
    ECR -. "5. Pull Image" .-> Backend
Technologies Used
Cloud Provider: AWS (VPC, ALB, EC2, S3, RDS, EKS, IAM, ECR)

Infrastructure as Code: Terraform

Configuration Management: Ansible

CI/CD Engine: Jenkins (Groovy DSL)

Containerization & Orchestration: Docker, Kubernetes

Security & Scanning: SonarQube (SAST), Trivy (CVE/Image Scanning)

Application Stack: Java / Spring Boot (Backend), React.js / Vite (Frontend), PostgreSQL (Database)

Project Structure
Plaintext
instamart-devops/
├── frontend/               # React/Vite source code and UI assets
├── backend/                # Spring Boot source code and Maven configs
├── terraform/              # IaC for VPC, EKS, RDS, and IAM roles
├── ansible/                # Playbooks for CI/CD server bootstrapping
├── k8s/                    # Kubernetes manifests (Deployments, Services)
├── Jenkinsfile             # Declarative CI/CD pipeline definition
└── README.md
Prerequisites
To deploy and modify this infrastructure, you will need the following installed on your local control machine:

AWS CLI (Configured with Administrator or equivalent IAM access)

Terraform (v1.5.0+)

kubectl (Configured to match the EKS cluster version)

Git & Node.js/Maven (For local development/testing)

An active Jenkins Server with Docker, SonarQube, and AWS credentials configured.

Setup Instructions
1. Clone the Repository
Bash
git clone [https://github.com/your-username/instamart.git](https://github.com/your-username/instamart.git)
cd instamart
2. Configure Environment Variables
Update the terraform.tfvars file with your specific AWS region, instance types, and database credentials.

3. Bootstrap the Database
Execute the initial SQL schemas located in /backend/src/main/resources/schema.sql against your target PostgreSQL instance.

Infrastructure Setup
Infrastructure is provisioned deterministically using Terraform, utilizing an S3 backend for state locking.

Bash
cd terraform/
terraform init
terraform plan -out=production.tfplan
terraform apply "production.tfplan"
Note: EKS cluster provisioning takes approximately 15 minutes.

Configuration Management
Ansible is utilized to eliminate manual server configuration for our CI/CD architecture. Playbooks are executed against raw EC2 instances to:

Install container runtimes (Docker).

Configure Jenkins build agents and Java/Maven environments.

Install required security binaries (Trivy, SonarScanner).

Pipeline Stages
The application lifecycle is fully automated using a multi-branch Jenkins pipeline, enforcing Shift-Left security:

Code Checkout: Pulls latest feature branch from Git.

SAST (SonarQube): Scans code patterns for security flaws or hardcoded secrets.

Build: Compiles backend .jar or builds frontend static assets.

Vulnerability Scan (Trivy): Sweeps the Docker image for OS and application-layer CVEs.

Registry Push: Authenticates and pushes secure images to Amazon ECR.

EKS Deployment: Executes kubectl apply to trigger rolling updates.

Deployment
Deployments to the Kubernetes cluster are handled automatically by Jenkins. The cluster uses a RollingUpdate strategy to ensure zero downtime.

Frontend: Jenkins dynamically injects the ALB endpoint into .env.production at build time, then syncs assets to the S3 bucket.

Backend: Jenkins updates the image tag in k8s/backend.yaml and applies the manifest to the EKS cluster.

Rollback Mechanism
In the event of a failed deployment or application panic, rapid rollbacks are executed via Kubernetes replica history management.

To instantly revert the backend to the previous stable state:

Bash
kubectl rollout undo deployment/instamart-backend
For database rollbacks, RDS automated snapshots are maintained with a 7-day retention period for point-in-time recovery.

Monitoring
Observability is critical for maintaining Service Level Objectives (SLOs).

Infrastructure Logs: AWS CloudWatch captures VPC Flow Logs, ALB Access Logs, and EKS Control Plane logs.

Application Metrics: The Spring Boot Actuator endpoint exposes system metrics (CPU, Memory, HTTP response times).

(Planned Phase): Integration of Prometheus for metric scraping and Grafana for dynamic observability dashboards.

Troubleshooting (SRE Case Studies)
1. Client-Side Build-Time Environment Variable Ingestion
Issue: The frontend React application threw net::ERR_CONNECTION_REFUSED errors, attempting to call localhost:8080 instead of the AWS Load Balancer. The .env file was correctly isolated via .gitignore, causing the Vite build engine to default to local endpoints.
Fix: Integrated dynamic variable-injection inside the Jenkinsfile. The pipeline builds a localized .env.production file containing the ALB URL directly in the build workspace, forcing Vite to bake the dynamic cloud DNS into the production JavaScript bundles.

2. Resolving Non-Interactive Database Automation Blocks
Issue: PostgreSQL bootstrap automation scripts stalled indefinitely during pipeline execution because the psql interface paused for manual password entry inside a non-interactive CI/CD shell.
Fix: Programmatically exported the PGPASSWORD environment variable within a scoped Linux subshell immediately before executing database seed routines, achieving successful zero-touch data tier bootstrapping.

3. Mitigating Database Migration Constraint Locks
Issue: Backend instances failed to initialize during CI/CD rollouts because automated Hibernate schema sync hooks collided with active relational database views.
Fix: Transitioned the SPRING_JPA_HIBERNATE_DDL_AUTO variable from update to validate in production profiles, shifting database governance away from dynamic runtime alterations toward deterministic validations.
