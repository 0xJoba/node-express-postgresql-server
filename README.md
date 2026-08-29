# Node Express PostgreSQL — Docker, Kubernetes & CI/CD

A Node.js REST API built with Express and PostgreSQL, containerized with Docker and deployed to Kubernetes.

## Tech Stack

* Node.js
* Express
* PostgreSQL
* Sequelize
* Docker
* Kubernetes
* GitHub Actions
* GitHub Container Registry (GHCR)

## Application Features

REST API endpoints for:

* `/users`
* `/users/:id`
* `/messages`
* `/messages/:id`

## Local Development

### Requirements

* Node.js
* npm
* Git
* Docker

### Installation

```bash
git clone https://github.com/0xJoba/node-express-postgresql-server.git
cd node-express-postgresql-server
npm install
```

The application uses environment variables for its database configuration.

Do not commit `.env` files or database credentials.

---

# Docker

Build the application image:

```bash
docker build -t node-express-postgresql-server .
```

Run the image:

```bash
docker run --rm -p 3000:3000 node-express-postgresql-server
```

The Docker image is also published to GitHub Container Registry.

```text
ghcr.io/0xjoba/node-express-postgresql-server:latest
```

---

# Kubernetes Deployment

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

The architecture consists of:

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
```

The Node API connects to PostgreSQL through the Kubernetes service:

```text
postgres:5432
```

## Create the PostgreSQL Secret

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

## Deploy to Kubernetes

Apply the manifests:

```bash
kubectl apply -f k8s/
```

Check the resources:

```bash
kubectl get pods
kubectl get services
```

The expected result is for both the Node API and PostgreSQL pods to reach `Running`.

## Access the API

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

---

# CI/CD Pipeline

GitHub Actions automatically builds and publishes the Docker image when changes are pushed to the `main` branch.

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Checkout repository
   │
   ├── Authenticate with GHCR
   │
   ├── Build Docker image
   │
   └── Push image to GHCR
          │
          ▼
       GHCR
```

The workflow is located at:

```text
.github/workflows/ci-cd.yml
```

The pipeline publishes:

```text
ghcr.io/0xjoba/node-express-postgresql-server:latest
```

and a commit-specific image:

```text
ghcr.io/0xjoba/node-express-postgresql-server:<git-sha>
```

---

# Security

* `.env` files are excluded from Git.
* Database credentials are stored in Kubernetes Secrets.
* No real database password is committed to the repository.
* Docker images are published through GitHub Container Registry.
* Kubernetes configuration is stored as declarative manifests.

## Verification

The complete deployment can be verified with:

```bash
kubectl get pods
kubectl get svc
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
