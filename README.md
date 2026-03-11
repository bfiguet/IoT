# Inception of Things (IoT)

This project is an introduction to **Kubernetes** using lightweight distributions and tools such as **K3s**, **K3d**, **Vagrant**, **Argo CD**, and **GitLab**.

The objective is to understand how to deploy and manage containerized applications using Kubernetes while automating deployments through **GitOps principles**.

The project is divided into **three mandatory parts** and an **optional bonus**.


# Part 1 – K3s and Vagrant

The goal of this part is to set up a **minimal Kubernetes cluster using K3s** on two virtual machines managed by **Vagrant**.

## Architecture

```
Server (Controller)
192.168.56.110
K3s Server

        │
        │
        ▼

ServerWorker
192.168.56.111
K3s Agent
```

## Requirements

Two virtual machines are created:

| Machine     | Role       | IP             |
| ----------- | ---------- | -------------- |
| `<login>S`  | K3s Server | 192.168.56.110 |
| `<login>SW` | K3s Worker | 192.168.56.111 |

Features:

* SSH access without password
* minimal resources (1 CPU / 512–1024MB RAM)
* K3s server on controller
* K3s agent on worker
* `kubectl` installed

The Vagrantfile automatically provisions the machines and installs K3s.

---

# Part 2 – K3s and Three Applications

This part runs **three web applications** inside a K3s cluster and exposes them using **Ingress routing based on the HTTP Host header**.

## Architecture

```
Client
   │
   ▼
192.168.56.110

Ingress Controller
   │
   ├── app1 → app1.com
   ├── app2 → app2.com (3 replicas)
   └── app3 → default
```

## Behaviour

| Host Header | Application Returned |
| ----------- | -------------------- |
| app1.com    | app1                 |
| app2.com    | app2 (3 replicas)    |
| other       | app3                 |

This demonstrates:

* Kubernetes **Deployments**
* **Services**
* **Ingress routing**

---

# Part 3 – K3d and Argo CD

In this part the cluster runs **locally using K3d (K3s in Docker)**.

The objective is to implement a **GitOps workflow using Argo CD**.

## Tools

* Docker
* K3d
* Kubernetes
* Argo CD
* GitHub repository

## Setup

The cluster and required tools are installed with:

```
p3/scripts/setup.sh
```

Example execution:

```
cd p3/scripts
sudo ./setup.sh
```

This script installs:

* Docker
* kubectl
* k3d
* Kubernetes cluster
* Argo CD
* required namespaces

## Namespaces

```
argocd
dev
```

## Deployment flow

```
GitHub repository
        │
        ▼
Argo CD
        │
        ▼
Kubernetes cluster
        │
        ▼
Application deployed in namespace dev
```

Argo CD continuously monitors the repository and synchronizes the cluster automatically.

## Application versions

The deployed application has two versions: v1 & v2

Changing the image tag in the repository automatically updates the running application.

Example:

```
image: wil42/playground:v1
```

update to:

```
image: wil42/playground:v2
```

Argo CD detects the change and redeploys the application.

---

# Bonus – GitLab Integration

The bonus part extends the infrastructure by **adding a local GitLab instance** running inside the Kubernetes cluster.

GitLab replaces GitHub as the Git repository used by Argo CD.

## Additional Namespace

```
gitlab
```

## Architecture

```
GitLab (local)
      │
      ▼
Argo CD
      │
      ▼
Kubernetes cluster
      │
      ▼
Application deployed in namespace dev
```

## Installation

The entire bonus environment can be installed using:

```
bonus/scripts/setup.sh
```

This script installs:

* Docker
* kubectl
* k3d cluster
* Helm
* Argo CD
* GitLab (via Helm chart)

## GitLab configuration

After installation:

1. Access GitLab
2. Create a repository
3. Push the Kubernetes manifests
4. Connect Argo CD to the repository

Argo CD then automatically deploys the application from the GitLab repository.

---

# Useful Commands

Check cluster status:

```
kubectl get nodes
```

Check namespaces:

```
kubectl get ns
```

Check pods:

```
kubectl get pods -A
```

Check Argo CD pods:

```
kubectl get pods -n argocd
```

Check application pods:

```
kubectl get pods -n dev
```

Check GitLab pods:

```
kubectl get pods -n gitlab
```

Access Argo CD UI:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```
https://localhost:8080
```

Retrieve Argo CD admin password:

```
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

---

# Technologies Used

* Kubernetes
* K3s
* K3d
* Docker
* Vagrant
* Argo CD
* GitLab
* Helm

---

# Learning Objectives

This project introduces several key DevOps concepts:

* Kubernetes cluster management
* Container orchestration
* Infrastructure automation
* GitOps workflows
* Continuous deployment
* Local development clusters
