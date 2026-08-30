# Node Express PostgreSQL — Docker, Kubernetes & CI/CD

A Node.js REST API built with Express and PostgreSQL, containerized with Docker, deployed to Kubernetes, and automatically built, published, and deployed using GitHub Actions.

---

## Tech Stack

* Node.js
* Express
* PostgreSQL
* Sequelize
* Docker
* Docker Compose
* Kubernetes
* GitHub Actions
* GitHub Container Registry (GHCR)
* GitHub Actions Self-hosted Runner

---

## Application Features

REST API endpoints for:

* `/users`
* `/users/:id`
* `/messages`
* `/messages/:id`

---

# Architecture

The application uses Docker for containerization, GitHub Container Registry for storing images, GitHub Actions for CI/CD, and Docker Desktop Kubernetes for the local Kubernetes environment.

```text
Developer
   │
   │ git push
   ▼
GitHub Repository
   │
   ▼
GitHub Actions
   │
   ├── Checkout repository
   │
   ├── Authenticate with GHCR
   │
   ├── Build Docker image
   │      ├── :latest
   │      └── :<git-sha>
   │
   └── Push image to GHCR
              │
              ▼
             GHCR
              │ Image Pull
              ▼
   Self-hosted GitHub Actions Runner
              │
              │ kubectl
              ▼
      Docker Desktop Kubernetes
              │
        ┌─────┴──────────────┐
        │                    │
        ▼                    ▼
     Node API             PostgreSQL
    Deployment            Deployment
        │                    │
        ▼                    ▼
   NodePort Service       ClusterIP
        │                    │
        └─────────┐    ┌─────┘
                  ▼    ▼
                API ↔ Database
                       │
                       ▼
                      PVC
```

---

# Local Development

## Requirements

* Node.js
* npm
* Git
* Docker
* Docker Compose
* kubectl
* Docker Desktop with Kubernetes enabled

## Installation

```bash
git clone https://github.com/0xJoba/node-express-postgresql-server.git
cd node-express-postgresql-server
npm install
```

The application uses environment variables for its database configuration.

Do not commit `.env` files or database credentials.

---

# Docker

The application is containerized using a multi-stage Docker build.

The Dockerfile separates dependency installation from the final application image to keep the final image cleaner and reduce unnecessary build artifacts.

Build the image locally:

```bash
docker build -t node-express-postgresql-server .
```

Run the container:

```bash
docker run -p 3000:3000 node-express-postgresql-server
```

---

# Docker Compose

Docker Compose is also provided for local development.

The Compose configuration can be used to run the Node.js application and PostgreSQL together without Kubernetes.

```bash
docker compose up --build
```

To stop the services:

```bash
docker compose down
```

---

# Kubernetes Deployment

## Kubernetes Environment

This project uses **Kubernetes provided by Docker Desktop** running locally on Windows.

Docker Desktop Kubernetes was chosen because it provides a simple local Kubernetes environment without requiring a separate VM or a cloud Kubernetes cluster.

The Kubernetes manifests are located in:

```text
k8s/
├── app-deployment.yaml
├── app-service.yaml
├── configmap.yaml
├── postgres-deployment.yaml
├── postgres-pvc.yaml
├── postgres-service.yaml
└── postgres-secret.example.yaml
```

---

## Kubernetes Architecture

The Kubernetes deployment consists of:

```text
                    Kubernetes Cluster
                           │
             ┌─────────────┴─────────────┐
             │                           │
        Node API                     PostgreSQL
       Deployment                    Deployment
             │                           │
        NodePort Service            PostgreSQL Service
             │                           │
             └──────────────┬────────────┘
                            │
                     PostgreSQL Database
                            │
                           PVC
```

The Node API connects to PostgreSQL through the Kubernetes Service:

```text
postgres:5432
```

The `postgres` hostname is resolved through Kubernetes DNS and points to the PostgreSQL ClusterIP Service.

---

# Kubernetes Configuration

## ConfigMap

The application uses a Kubernetes ConfigMap for non-sensitive configuration.

```text
DATABASE
DATABASE_HOST
PORT
```

The current configuration is:

```yaml
DATABASE: mydatabase
DATABASE_HOST: postgres
PORT: "3000"
```

The database host is `postgres`, which corresponds to the PostgreSQL Kubernetes Service.

---

## PostgreSQL Secret

The repository does not contain a real database password.

Create the Kubernetes Secret locally:

```bash
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=YOUR_PASSWORD
```

Replace `YOUR_PASSWORD` with a password of your choice.

The example manifest is provided for reference:

```text
k8s/postgres-secret.example.yaml
```

Database credentials are therefore not committed to the repository.

---

# Kubernetes Services

## Node API — NodePort

The Node API uses a `NodePort` Service.

```yaml
type: NodePort
```

This allows the API to be accessed externally from the local Kubernetes cluster.

Check the assigned port:

```bash
kubectl get svc node-api
```

The current local configuration exposes the API on:

```text
localhost:30588
```

The assigned NodePort may differ depending on the Kubernetes configuration, so use `kubectl get svc node-api` to verify the current port.

Test the API:

```bash
curl http://localhost:30588/users
```

---

## PostgreSQL — ClusterIP

PostgreSQL uses a `ClusterIP` Service:

```yaml
type: ClusterIP
```

PostgreSQL does not need to be exposed outside the Kubernetes cluster.

The Node API communicates with PostgreSQL internally using:

```text
postgres:5432
```

This keeps the database internal to the Kubernetes cluster while allowing the application to access it through Kubernetes service discovery.

---

# PostgreSQL Persistent Storage

PostgreSQL uses a Kubernetes `PersistentVolumeClaim` named:

```text
postgres-pvc
```

The PVC requests:

```text
1Gi
```

with:

```text
ReadWriteOnce
```

The PostgreSQL Deployment mounts the persistent volume at:

```text
/var/lib/postgresql/data
```

The relationship is:

```text
PostgreSQL Container
        │
        ▼
/var/lib/postgresql/data
        │
        ▼
postgres-storage
        │
        ▼
postgres-pvc
        │
        ▼
Persistent Storage
```

The PVC provides persistent storage outside the lifecycle of an individual PostgreSQL pod. This means that when the PostgreSQL pod is recreated, its database data can remain backed by the persistent volume rather than existing only inside the pod's writable container filesystem.

The PVC can be checked with:

```bash
kubectl get pvc
```

---

## Database Synchronization Note

The original application uses Sequelize synchronization behavior with destructive database reset behavior enabled for the demo environment.

This is acceptable for the assessment/demo setup but would not be appropriate for a production database.

In a production implementation, database migrations would be used instead of destructive schema synchronization to prevent accidental data loss during application startup.

---

# Kubernetes Health Checks

The Node API Deployment includes both readiness and liveness probes.

### Readiness Probe

```text
/users
```

The readiness probe determines whether the application is ready to receive traffic.

### Liveness Probe

```text
/users
```

The liveness probe helps Kubernetes determine whether the application is still functioning correctly.

The probes allow Kubernetes to monitor the health of the Node API automatically.

---

# Deploy to Kubernetes

Before deploying, make sure Docker Desktop Kubernetes is enabled and the PostgreSQL Secret has been created.

Apply the manifests:

```bash
kubectl apply -f k8s/
```

Check the resources:

```bash
kubectl get pods
kubectl get services
kubectl get pvc
```

The expected result is for both the Node API and PostgreSQL pods to reach:

```text
Running
```

Check the Node API rollout:

```bash
kubectl rollout status deployment/node-api
```

Check the PostgreSQL rollout:

```bash
kubectl rollout status deployment/postgres
```

---

# Access the API

The Node API is exposed through a Kubernetes NodePort.

Check the assigned port:

```bash
kubectl get svc node-api
```

For the current configuration, the API is exposed on:

```text
localhost:30588
```

Test the API:

```bash
curl http://localhost:30588/users
```

Example response:

```json
[
  {
    "id": 1,
    "username": "rwieruch"
  },
  {
    "id": 2,
    "username": "ddavids"
  }
]
```

A successful response confirms that the Node.js API is running and communicating with PostgreSQL through the Kubernetes Service.

---

# CI/CD Pipeline

GitHub Actions automatically builds, publishes, and deploys the application when changes are pushed to the `main` branch.

The workflow is located at:

```text
.github/workflows/ci-cd.yml
```

The pipeline consists of two jobs:

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ▼
build-and-push
   │
   ├── Checkout repository
   │
   ├── Authenticate with GHCR
   │
   ├── Build Docker image
   │      ├── :latest
   │      └── :<git-sha>
   │
   └── Push images to GHCR
              │
              ▼
             GHCR
              │
              ▼
           deploy
              │
              ▼
   Self-hosted GitHub Actions Runner
              │
              ├── kubectl set image
              │
              └── kubectl rollout status
              │
              ▼
      Docker Desktop Kubernetes
              │
              ▼
        Node API Deployment
```

The deployment job depends on the build-and-push job completing successfully.

```yaml
needs: build-and-push
```

This ensures that the deployment does not run until the Docker image has been successfully built and pushed to GHCR.

---

# Docker Image Tags

The pipeline publishes two image tags.

### Latest

```text
ghcr.io/0xjoba/node-express-postgresql-server:latest
```

### Commit-specific image

```text
ghcr.io/0xjoba/node-express-postgresql-server:<git-sha>
```

The Git SHA is the unique identifier of the Git commit that triggered the workflow.

For example:

```text
Git commit
    ↓
Git SHA
    ↓
Docker image tag
    ↓
GHCR
    ↓
Kubernetes
```

Using the Git SHA as an image tag provides version traceability because a deployed image can be directly associated with the source commit that produced it.

The SHA is therefore used for **version identification and traceability**, not for service-to-service communication.

---

# GitHub Container Registry

GitHub Container Registry (GHCR) is used to store the Docker images produced by the CI/CD pipeline.

The workflow authenticates to GHCR using the GitHub Actions token:

```yaml
password: ${{ secrets.GITHUB_TOKEN }}
```

The workflow also grants the required package permission:

```yaml
permissions:
  contents: read
  packages: write
```

This allows GitHub Actions to publish the Docker image to the repository's container registry.

---

# Self-hosted GitHub Actions Runner

The deployment job runs on a self-hosted GitHub Actions runner:

```yaml
runs-on: self-hosted
```

The self-hosted runner is running on the local Windows development machine.

This is necessary because the Kubernetes cluster is running locally through Docker Desktop.

The deployment flow is therefore:

```text
GitHub Actions
      │
      ▼
Self-hosted Runner
      │
      │ kubectl
      ▼
Docker Desktop Kubernetes
```

The self-hosted runner allows the deployment job to execute `kubectl` against the local Kubernetes cluster.

The build-and-push job continues to use a GitHub-hosted runner.

---

# Deployment Process

When code is pushed to `main`:

1. GitHub Actions checks out the repository.
2. GitHub Actions authenticates with GHCR.
3. Docker builds the application image.
4. The image receives both `latest` and Git-SHA tags.
5. The images are pushed to GHCR.
6. The deployment job runs on the self-hosted runner.
7. `kubectl set image` updates the Node API Deployment to the new Git-SHA image.
8. Kubernetes performs the rollout.
9. `kubectl rollout status` waits for the deployment to complete successfully.

The deployment command is equivalent to:

```bash
kubectl set image deployment/node-api \
  node-api=ghcr.io/0xjoba/node-express-postgresql-server:<git-sha>
```

The rollout is then verified with:

```bash
kubectl rollout status deployment/node-api
```

---

# Security

* `.env` files are excluded from Git.
* Database credentials are stored in Kubernetes Secrets.
* No real database password is committed to the repository.
* Docker images are published through GitHub Container Registry.
* Kubernetes configuration is stored as declarative manifests.
* The PostgreSQL database is exposed internally through a ClusterIP Service rather than externally.
* The deployment uses a commit-specific Docker image tag rather than relying exclusively on `latest`.

---

# Tools and Design Choices

## Docker

Docker is used to package the Node.js application and its dependencies into a portable container image.

This makes the application easier to run consistently across environments.

## Docker Compose

Docker Compose provides an additional lightweight option for local application development without requiring Kubernetes.

## Kubernetes

Kubernetes is used to orchestrate the application and PostgreSQL workloads, manage deployments and services, perform health checks, and provide persistent storage.

## Docker Desktop Kubernetes

Docker Desktop Kubernetes was chosen as the local Kubernetes environment because it provides a simple way to run Kubernetes locally without requiring a separate VM or cloud cluster.

## GitHub Actions

GitHub Actions is used to automate the build, image publishing, and deployment workflow whenever changes are pushed to `main`.

## GitHub Container Registry

GHCR is used as the container registry for storing the Docker images produced by the CI/CD pipeline.

## Self-hosted GitHub Actions Runner

A self-hosted runner is used for the deployment stage because the target Kubernetes cluster is running locally on Docker Desktop.

This allows the deployment job to execute `kubectl` against the local cluster.

## ConfigMap

A Kubernetes ConfigMap is used for non-sensitive application configuration such as:

```text
DATABASE
DATABASE_HOST
PORT
```

## Kubernetes Secret

A Kubernetes Secret is used for PostgreSQL credentials so that the actual database password does not need to be stored in the repository.

## PersistentVolumeClaim

A PersistentVolumeClaim is used to provide persistent storage for PostgreSQL data outside the lifecycle of an individual PostgreSQL pod.

---

# Assumptions and Trade-offs

* Kubernetes is running locally through Docker Desktop rather than on a managed cloud cluster.
* PostgreSQL is deployed as a single Kubernetes Deployment because this is a local technical assessment rather than a production database architecture.
* A NodePort Service is used to expose the API externally from the local Kubernetes cluster.
* PostgreSQL uses a ClusterIP Service because it only needs to be accessible internally by the Node.js application.
* A self-hosted GitHub Actions runner is used for deployment because the Kubernetes cluster is running locally.
* The PostgreSQL credentials are created locally as a Kubernetes Secret and are not committed to the repository.
* The application currently uses Sequelize synchronization behavior suitable for the original demo application; a production implementation would use database migrations instead.
* The PostgreSQL Deployment uses a single replica. A production database architecture would require a more robust availability and backup strategy.
* Docker Desktop Kubernetes is used for simplicity and reproducibility during the assessment rather than deploying to a cloud Kubernetes service.

---

# Verification

The complete deployment can be verified with:

```bash
kubectl get pods
kubectl get svc
kubectl get pvc
```

Verify the exact image deployed:

```bash
kubectl get deployment node-api -o jsonpath="{.spec.template.spec.containers[0].image}"
```

The result should contain the Git SHA associated with the deployment, for example:

```text
ghcr.io/0xjoba/node-express-postgresql-server:<git-sha>
```

Finally, test the API:

```bash
curl http://localhost:30588/users
```

A successful API response confirms that:

```text
Node API
   ↓
Kubernetes Service
   ↓
PostgreSQL
```

are communicating successfully.

---

# Improvements With More Time

For a production implementation, I would consider:

* Replacing the PostgreSQL Deployment with a StatefulSet or a managed PostgreSQL service.
* Using database migrations instead of destructive schema synchronization.
* Adding automated application and integration tests to the CI pipeline.
* Adding container vulnerability scanning.
* Using a dedicated production Kubernetes cluster rather than Docker Desktop.
* Adding CPU and memory resource requests and limits to Kubernetes workloads.
* Using an Ingress controller instead of NodePort for application exposure.
* Managing secrets through a dedicated secret-management solution.
* Adding monitoring and centralized logging.
* Using separate development, staging, and production environments.
* Adding automated rollback strategies for failed deployments.
* Adding Kubernetes resource health checks and stronger deployment policies.
* Adding database backups and recovery procedures.
* Using a more highly available PostgreSQL architecture for production workloads.

---

# Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── k8s/
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── configmap.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-pvc.yaml
│   ├── postgres-secret.example.yaml
│   └── postgres-service.yaml
│
├── src/
│   ├── models/
│   └── routes/
│
├── Dockerfile
├── docker-compose.yml
├── package.json
├── package-lock.json
└── README.md
```

---

# Summary

This project demonstrates a complete containerized application deployment workflow:

```text
Source Code
    ↓
GitHub
    ↓
GitHub Actions
    ↓
Docker Build
    ↓
GHCR
    ↓
Self-hosted Runner
    ↓
kubectl
    ↓
Docker Desktop Kubernetes
    ↓
Node.js API
    ↓
PostgreSQL Service
    ↓
PostgreSQL
    ↓
PersistentVolumeClaim
```

The implementation demonstrates containerization, Kubernetes deployment, service discovery, configuration management, secret management, persistent storage, health checks, container image versioning, and CI/CD automation.
