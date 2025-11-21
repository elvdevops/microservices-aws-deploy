# Senior DevOps Capstone

> End-to-end DevOps project: Deploy a 3-service microservices application on AWS EKS using Terraform, Docker, Helm, and CI/CD with monitoring, security, and GitOps.

---

![Architecture Diagram](/mnt/data/A_digital_diagram_in_the_image_depicts_a_cloud-bas.png)

*Local file path shown above — the diagram image is saved at `/mnt/data/A_digital_diagram_in_the_image_depicts_a_cloud-bas.png`.*

---

## Project Summary

This project takes you through a practical, interview-ready Senior DevOps workflow:

- Infrastructure as Code with **Terraform** (VPC, EKS, ECR, S3, IAM)
- Containerization with **Docker** and secure image builds
- Kubernetes deployment using **Helm** charts
- CI/CD pipelines using **GitHub Actions** or **Jenkins** (build → scan → push → deploy)
- GitOps delivery with **ArgoCD** (optional, recommended)
- Observability with **Prometheus**, **Grafana**, and **Loki**
- Secrets management with **AWS Secrets Manager** + External Secrets Operator
- DevSecOps: image scanning (Trivy), code analysis (SonarQube/Snyk) and policy enforcement (OPA/Gatekeeper)
- Scaling, backups, and basic DR

The repo is organized to be portfolio-ready and demonstrates senior-level design, automation, operations, and documentation.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Layout](#repository-layout)
3. [Quick Start (3-step)](#quick-start-3-step)
4. [Detailed Setup](#detailed-setup)
   - [Infrastructure (Terraform)](#infrastructure-terraform)
   - [Container builds & ECR](#container-builds--ecr)
   - [Kubernetes (Helm)](#kubernetes-helm)
   - [CI/CD Pipelines](#cicd-pipelines)
   - [Monitoring & Logging](#monitoring--logging)
   - [Secrets & Security](#secrets--security)
   - [Backups & DR](#backups--dr)
5. [Deployment workflows](#deployment-workflows)
6. [Testing & Load](#testing--load)
7. [Cost & Cleanup](#cost--cleanup)
8. [Troubleshooting](#troubleshooting)
9. [Contributing & License](#contributing--license)

---

## Prerequisites

- AWS account with permissions to create VPC/EKS/IAM/ECR/S3
- `terraform` installed (v1.2+ recommended)
- `aws` CLI configured (`aws configure`)
- `kubectl` installed
- `helm` installed
- `docker` installed and running
- `git` and a GitHub account
- Optional: Jenkins server or GitHub Actions enabled on repo

---

## Repository Layout

```
/README.md
/infra/                # Terraform modules & root configs
/helm/                 # Helm chart(s) for the 3 services
/k8s/                  # Kubernetes plain manifests (for reference)
/app/                  # source for each microservice
  /service-auth/
  /service-api/
  /service-frontend/
/docker/               # Dockerfiles and build scripts
/cicd/                 # Jenkinsfile or .github/workflows/
/monitoring/           # Prometheus, Grafana, Loki helm values & dashboards
/docs/                 # diagrams, runbooks, screenshots
/scripts/              # helper scripts (push-image, helm-deploy, etc.)

```

---

## Quick Start (3-step)

1. **Provision infra (Terraform)**
   ```bash
   cd infra
   terraform init
   terraform apply
   ```
   This creates the VPC, EKS cluster, ECR repos, S3 backend (if configured), and IAM roles.

2. **Build & push images (Docker → ECR)**
   ```bash
   cd docker
   ./push-all-to-ecr.sh  # Or build/push per-service
   ```

3. **Deploy to Kubernetes (Helm)**
   ```bash
   cd helm
   helm upgrade --install myapp ./ --namespace dev --create-namespace
   kubectl get svc -n dev
   ```

Open the ALB DNS printed by the Ingress/Load Balancer to verify the frontend.

---

## Detailed Setup

### Infrastructure (Terraform)

- Use modular Terraform: `modules/vpc`, `modules/eks`, `modules/ecr`, `modules/iam`.
- Store state in S3 with DynamoDB for locks (recommended):

```hcl
backend "s3" {
  bucket = "<your-tfstate-bucket>"
  key    = "project/tfstate"
  region = "us-east-1"
}
```

- Important outputs from Terraform:
  - `kubeconfig` (or a kubeconfig file path)
  - ECR repo URIs for each service
  - ALB DNS name

### Container builds & ECR

- Use multi-stage Dockerfiles to minimize image size.
- Tag images with `${REPO_URI}:${GIT_SHA}`.
- Push images to ECR and enable lifecycle policies to keep the repo tidy.
- Add `trivy` scan in CI stage to fail builds on high/critical vulnerabilities.

Example push script (simplified):

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI
docker build -t service-api:latest ./app/service-api
docker tag service-api:latest $ECR_URI/service-api:latest
docker push $ECR_URI/service-api:latest
```

### Kubernetes (Helm)

- Single umbrella Helm chart `helm/myapp` with subcharts or template values for each service.
- Use `values.yaml` per environment: `values.dev.yaml`, `values.prod.yaml`.
- Add `readinessProbe` and `livenessProbe` to deployments.
- Use HPA for autoscaling and set resource requests/limits.

Deploy:

```bash
helm upgrade --install myapp ./helm -f values.dev.yaml --namespace dev --create-namespace
```

### CI/CD Pipelines

**Recommended: GitHub Actions** (simple to start). Pipeline stages:
1. Checkout
2. Build & unit test
3. Build Docker image
4. Run Trivy scan
5. Push to ECR
6. Update Helm values with new image tag
7. Deploy to Kubernetes (helm upgrade)

**Jenkins**: Use Jenkins agents with Docker & kubectl. Store credentials in Jenkins Credentials store.

### GitOps (ArgoCD)

- Create a `gitops/` repo or a `prod` branch with Kustomize overlays.
- Install ArgoCD in cluster and point it at your repo for automatic sync.

### Monitoring & Logging

- Install `kube-prometheus-stack` via Helm (Prometheus + Grafana).
- Install `loki` + `promtail` for log aggregation and add Grafana datasource.
- Create dashboards for:
  - Node/cluster health
  - Pod CPU/memory
  - App-level metrics (request latencies, error rates)
- Add Alertmanager rules for critical alerts and integrate with Slack/Email.

### Secrets & Security

- Use **AWS Secrets Manager** as the secrets source.
- Deploy External Secrets Operator to sync secrets into Kubernetes as `Secret` objects.
- Use IAM roles for service accounts (IRSA) so pods can access AWS resources with least privilege.
- Add OPA Gatekeeper or Kyverno for policy enforcement (deny privileged containers, require resource limits).

### Backups & Disaster Recovery

- Use RDS automated backups / snapshots for PostgreSQL.
- Enable S3 versioning and lifecycle rules for artifact buckets.
- Schedule etcd / cluster state backups (e.g., Velero for snapshots).

---

## Deployment workflows

- **Feature branch → PR** → runs unit tests and image build in CI.
- **Merge to `main`** → pipeline pushes image to ECR and deploys to `dev` namespace.
- **Promote to `prod`** → either manual pipeline step or merge to `prod` branch watched by ArgoCD.
- **Canary / Blue-Green**: use Argo Rollouts or service mesh traffic shaping (Istio/Linkerd).

---

## Testing & Load

- Unit tests for each service.
- Integration tests that run against a `dev` environment.
- Load tests with `k6` or `JMeter` to validate autoscaling behavior.

Example `k6` invocation:

```bash
k6 run loadtest.js
```

---

## Cost & Cleanup

- To avoid ongoing charges, tear down infra with Terraform destroy:

```bash
cd infra
terraform destroy
```

- Clean ECR images and S3 artifacts when not needed.

---

## Troubleshooting

- `kubectl get pods -A` — check crashloop/unsched
- `kubectl describe pod <pod>` — see events
- `kubectl logs <pod>` — container logs
- `terraform plan` — check drift
- Check ALB security groups and ingress rules if Load Balancer is not accessible

---

## Deliverables (What to include in your portfolio)

1. `infra/` Terraform code
2. `helm/` chart(s)
3. `cicd/` pipeline configs (Jenkinsfile or GitHub Actions workflows)
4. `app/` microservice source code (simple but complete)
5. Screenshots: Grafana, ArgoCD, Prometheus graphs
6. Architecture diagram (PNG stored at `/mnt/data/A_digital_diagram_in_the_image_depicts_a_cloud-bas.png`)
7. `README.md` (this file) and a short runbook

---

## Contributing

Feel free to open issues or PRs. Keep changes small and document new steps in `/docs`.

---

## License

This project is provided as-is for learning and portfolio use. Use an open source license if you plan to publish publicly (MIT recommended).
