# Architecture

This document outlines the architecture of the StudentAI application and the CI/CD pipeline.

## CI/CD Pipeline

The CI/CD pipeline is managed by Jenkins and is defined in the `jenkins/Jenkinsfile`. The pipeline consists of the following stages:

1.  **Checkout**: Checks out the source code from the Git repository.
2.  **Build & Push Backend Image**: Builds the Docker image for the backend application and pushes it to ECR.
3.  **Build & Push Frontend Image**: Builds the Docker image for the frontend application and pushes it to ECR.
4.  **Deploy to EKS**: Deploys the application to the EKS cluster using Helm.

## Kubernetes Architecture

The application is deployed to an EKS cluster and consists of the following components:

*   **Backend Deployment**: Manages the backend pods.
*   **Frontend Deployment**: Manages the frontend pods.
*   **Backend Service**: Exposes the backend pods within the cluster.
*   **Frontend Service**: Exposes the frontend pods within the cluster.
*   **Ingress**: Exposes the frontend service to the internet.

## Diagram

```
+-----------------+      +-----------------+      +-----------------+
|                 |      |                 |      |                 |
|     Jenkins     +------>     ECR         +------>      EKS        |
|                 |      |                 |      |                 |
+-----------------+      +-----------------+      +-----------------+
