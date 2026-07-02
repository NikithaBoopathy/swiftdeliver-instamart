# Instamart: Highly Available 3-Tier Enterprise DevSecOps Architecture

A production-grade, highly available, and secure 3-tier e-commerce application platform deployed on AWS using an automated, end-to-end DevSecOps CI/CD pipeline. This project documents the complete architectural transformation from a monolithic single-server baseline to an elastic, self-healing, multi-AZ containerized ecosystem governed by Infrastructure as Code (IaC) and Configuration as Code (CaC).

---

## 🏢 Platform Architecture Evolution

### Phase 1: Single-Instance Blueprint (Baseline State)
The initial environment utilizes a modular network topology focused on secure traffic cascading:
*   **Edge Routing:** Public subnets house an **AWS Application Load Balancer (ALB)** acting as the exclusive ingress point for public data interaction.
*   **Compute Tier:** The **Spring Boot Backend Engine** runs containerized inside an EC2 instance hosted within an isolated Private Subnet, completely shielded from direct internet entry.
*   **Data Tier:** An **Amazon RDS PostgreSQL** cluster resides in an isolated Data Subnet Group, accessible only via stateful Security Group rules originating from the compute tier.
*   **Static Asset Delivery:** The **React/Vite Frontend** application is decoupled into an independent static build bucket hosted via **Amazon S3** utilizing rigid Bucket Policies and Public Access Block overrides.

### Phase 2: Elastic Container Orchestration (Target Scale State)
To eliminate the single instance as a single point of failure (SPOF), the platform is actively transitioning to **Amazon Elastic Kubernetes Service (EKS)**:
*   **Managed Control Plane:** AWS orchestrates highly available Kubernetes master nodes across multiple Availability Zones (AZs).
*   **Managed Node Groups:** Worker workloads scale dynamically inside private subnets using EC2 Auto Scaling groups running an EKS-optimized Amazon Linux 2 AMI.
*   **Self-Healing Compute:** Spring Boot application containers migrate into highly available **Kubernetes Pods** governed by a `Deployment` manifest enforcing a `3-replica` state with automatic liveness/readiness probes.

---

## 🛠️ Unified Toolchain & SRE Governance

This architecture achieves strict immutability and automation across the lifecycle by separating concerns across a standardized toolset:

+-------------+     +---------------+     +---------------+     +-------------+
|  Terraform  | --> |    Ansible    | --> |    Jenkins    | --> |  Kubernetes |
|  (Provision) |     |  (Configure)  |     |  (Orchestrate)|     | (Scale Engine)|
+-------------+     +---------------+     +---------------+     +-------------+


### 1. HashiCorp Terraform (Infrastructure as Code)
Responsible for deterministic infrastructure creation. It prevents environment drift by enforcing a declarative blueprint of all AWS physical structures:
*   **Networking:** Custom VPC, Private/Public Subnets, Internet Gateways, NAT Gateways, and Route Tables.
*   **Identity (IAM):** Least-privilege assume-role policies linking EKS control planes, node groups, and service accounts securely.
*   **Compute & Data:** Provisioning the target EKS clusters, node configurations, and the persistent RDS database instances.
*   **State Governance:** Remote state management utilizing an **S3 Backend** combined with **DynamoDB State Locking** to guarantee safe concurrent team executions.

### 2. Ansible (Configuration as Code)
Responsible for setting up immutable software runtime states on target host servers. Ansible eliminates manual server configuration:
*   **Node Provisioning:** Programmatically installing container runtimes, configuring network kernels, and tuning SSH security standards.
*   **CI/CD Worker Bootstrap:** Automatically configuring Jenkins build agents, downloading Java/Maven environments, installing security binaries (Trivy), and provisioning Docker runtime engines locally.

### 3. Jenkins (DevSecOps Pipeline Engine)
The centralized automation brain. Jenkins translates Git repository events into an absolute, automated sequence of validation, testing, compilation, and cloud deployment steps.

---

## 🔄 End-to-End DevSecOps CI/CD Flow

The entire application lifecycle is fully automated using multi-branch Groovy-DSL pipelines, introducing security checks at every phase (Shift-Left Security):

[ Code Commit ] ──> [ SonarQube SAST ] ──> [ Maven Compile ] ──> [ Trivy CVE Scan ] ──> [ ECR Registry Push ] ──> [ Kubernetes Rolling Update ]


1.  **Code Ingestion:** Pipeline hooks capture code changes directly from GitHub feature branches.
2.  **Static Application Security Testing (SAST):** Enforces quality gates and scans code patterns for security flaws or hardcoded secrets via **SonarQube**.
3.  **Application Compilation:** Compiles Spring Boot source modules into deployable binary files (`.jar`) using a structured Maven runtime workspace.
4.  **Container Vulnerability Evaluation:** Builds target runtime container images and executes automated vulnerability sweeps via **Trivy**, flagging any unsafe OS packages or application dependencies before registry admission.
5.  **Secure Ingestion:** Authenticates with AWS credentials and uploads clean, tagged container images into an private **Amazon Elastic Container Registry (ECR)**.
6.  **Deterministic Release Execution:** Updates Kubernetes manifests with the distinct immutable build ID, connects to the EKS cluster API, and executes zero-downtime rolling upgrades across active replica pods via `kubectl`.

---
