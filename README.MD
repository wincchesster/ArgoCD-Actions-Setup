# DevOps with ArgoCD and GitHub Actions on EKS

This is a practical example of how to configure ArgoCD, GitHub Actions, and deploy applications using Kubernetes. This project is designed to demonstrate the key aspects of a DevOps engineer's workflow.

## Project Overview

This project includes:

1. A simple Python server that listens on port 80 and responds with status code 200 on /.
2. A Dockerfile to containerize the Python server.
3. GitHub Actions workflow to build and push the Docker image to Docker Hub.
4. Terraform code to create an EKS cluster, deploy ArgoCD using Helm, and configure a Route53 DNS record.
5. A Kubernetes manifest to deploy the app using ArgoCD.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup Guide](#setup-guide)
  - [Step 1: Python Server and Dockerfile](#step-1)
  - [Step 2: GitHub Actions Workflow](#step-2)
  - [Step 3: ArgoCD Service Files](#step-3)
  - [Step 4: Terraform Setup for EKS and ArgoCD](#step-4)
  - [Step 5: ArgoCD Application](#step-5)
- [Result](#result)
- [Conclusion](#conclusion)
- [Contributing](#contributing)
- [License](#license)

## <a name="prerequisites"></a>Prerequisites

- AWS CLI configured with the necessary permissions.
- Docker and Docker Hub account.
- Terraform installed.
- Kubernetes CLI (kubectl) installed.
- GitHub repository setup with necessary secrets.

## <a name="setup-guide"></a>Setup Guide

Before you begin, ensure you have the necessary prerequisites installed and configured. Also, create a new GitHub repository to store the application code. And create a new repository for the Terraform and ArgoCD configuration.
**`Files from step 1,2,3 should be located in the application repository. Files from step 4,5 should be located in the Terraform and ArgoCD repository.`**

App repository structure:

```
.
├── .github
│   └── workflows
│       └── build.yml
├── dev
│   └── deployment.yml
|   └── service.yml
|   └── ingress.yml
├── Dockerfile
└── server.py
```

</br>
</br>

---

### <a name="step-1"></a>Step 1: Python Server and Dockerfile

The Python server is a simple HTTP server implemented using Python's http.server module. The server listens on port 80 and responds with a simple HTML page.

#### Python Server Code (server.py):

```python
from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "0.0.0.0"
serverPort = 80

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/stress":
            self.simulate_load()

        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        if self.path == "/":
            self.wfile.write(bytes("<html><head><title>STEP 4</title>", "utf-8"))
            self.wfile.write(bytes("<style>", "utf-8"))
            self.wfile.write(bytes("body {background-color: black; color: white; height: 100vh; display: flex; justify-content: center; align-items: center; margin: 0; font-family: 'Montserrat', sans-serif;}", "utf-8"))
            self.wfile.write(bytes("</style></head>", "utf-8"))
            self.wfile.write(bytes("<body>", "utf-8"))
            self.wfile.write(bytes("<h1>Example</h1>", "utf-8"))
            self.wfile.write(bytes("</body></html>", "utf-8"))
        elif self.path == "/stress":
            self.wfile.write(bytes("<html><head><title>Stress Test</title></head>", "utf-8"))
            self.wfile.write(bytes("<body><h1>Stress Test Page</h1></body></html>", "utf-8"))

    def simulate_load(self):
        def fib(n):
            if n < 2:
                return n
            return fib(n - 1) + fib(n - 2)
        fib(32)

if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))
    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass
    webServer.server_close()
    print("Server stopped.")

```

#### Dockerfile:

```Dockerfile
FROM alpine:latest

RUN apk update && apk add --no-cache python3 py3-pip
WORKDIR /app
COPY . /app

CMD ["python3", "server.py"]
```

### <a name="step-2"></a>Step 2: GitHub Actions Workflow

The GitHub Actions workflow builds, tests, and pushes the Docker image to Docker Hub upon every push to the main branch.

#### GitHub Actions Workflow (`.github/workflows/build.yml`):

```yaml
name: action-1

on:
  push:
    branches:
      - main
    paths:
      - "server.py"
      - "Dockerfile"
  pull_request:
    branches:
      - main

jobs:
  build-test-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v1

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Log in to DockerHub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        id: build
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./Dockerfile
          push: false
          tags: <username>/example-app:latest

      - name: Test
        run: |
          docker run --rm -d -p 8080:80 --name test-container <username>/example-app:latest
          sleep 10 
          response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
          if [ "$response" -ne 200 ]; then
            echo "Test Failed: HTTP response is $response"
            exit 1
          fi
        env:
          GITHUB_TOKEN: ${{ secrets.ACCESS_TOKEN }}

      - name: Cleanup
        if: always()
        run: docker rm -f test-container

      - name: Update deployment.yml with commit hash
        if: success()
        run: |
          sed -i "s|image: <username>/example-app:.*|image: <username>/example-app:${{ github.sha }}|g" dev/deployment.yml

      - name: Commit updated deployment.yml
        if: success()
        env:
          GITHUB_TOKEN: ${{ secrets.ACCESS_TOKEN_WRITE }}
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add dev/deployment.yml
          git commit -m "Update deployment.yml with image tag ${{ github.sha }}"
          git push https://x-access-token:${{ secrets.ACCESS_TOKEN_WRITE }}@github.com/<username>/example-app.git HEAD:main

      - name: Push Docker image
        if: success()
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: <username>/example-app:latest, <username>/example-app:${{ github.sha }}
```

### <a name="step-3"></a>Step 3: ArgoCD Service Files

In the app repository, create the following Kubernetes service files: `dev/deployment.yml`, `dev/service.yml`, and `dev/ingress.yml`.

(`dev/deployment.yml`) contains the Kubernetes deployment manifest for the application.

(`dev/service.yml`) contains the Kubernetes service manifest for the application.

(`dev/ingress.yml`) contains the Kubernetes ingress manifest for the application.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: "app.mycluster.example.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-service
                port:
                  number: 80
```

Ingress is used to route traffic to the application service and is used to access the application from the internet on the specified domain.

**That it for the application repository. Now, let's move on to the Terraform and ArgoCD repository.**
</br>
</br>

---

### <a name="step-4"></a>Step 4: Terraform Setup for EKS and ArgoCD

Use Terraform files to create an EKS cluster, install ArgoCD using Helm, and set up Route53 DNS records.

#### ArgoCD installation using Helm (`argocd.tf`):

```hcl
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    <<EOF
server:
  service:
    type: LoadBalancer
  extraArgs:
    - --insecure
EOF
  ]
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "argocd.${var.name}"
  type    = "CNAME"
  ttl     = 300

  records = [
    data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
  ]

  depends_on = [helm_release.argocd]
}
```

After applying the Terraform configuration, you should have an EKS cluster running with ArgoCD installed.

Cluster view using k9s:
<img src="https://i.imgur.com/O4IPl8Y.png" alt="Result" width="90%">
</br>
ArgoCD web UI:
<img src="https://i.imgur.com/e51kxzu.png" alt="Result" width="90%">
</br>
To find the ArgoCD password, run the following command:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

</br>

> **Note:** Make sure to update the `argocd.tf` file with the correct domain name and Route53 zone ID.

> **Note:** After creating the EKS cluster, you need to configure `kubectl` to connect to the cluster. You can do this by running `aws eks --region <region> update-kubeconfig --name <cluster_name> --profile <your_profile>`.

</br>
</br>

### <a name="step-5"></a>Step 5: ArgoCD Application

Login to ArgoCD using command argocd

```bash
argocd login <argocd_server>
```

Add the application repository to ArgoCD using the following command:

```bash
argocd repo add <app_repository_url> --username <github_username> --password <github_token>
```

Create a Kubernetes manifest to deploy the application using ArgoCD.

#### ArgoCD Application Manifest (`dev/deployment.yml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: example-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "<app_repository_url>"
    targetRevision: HEAD
    path: dev
  destination:
    server: "https://kubernetes.default.svc"
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply the application manifest using the following command:

```bash
kubectl apply -f argocd/app.yaml
```

The application should now be deployed to the EKS cluster using ArgoCD.

<img src="https://i.imgur.com/NrGmje7.png" alt="Result" width="90%">

</br>

#### **Now after every push to the main branch, the GitHub Actions workflow will build, test and push the Docker image to Docker Hub if the tests pass. The deployment.yml file will be updated with the new image tag and pushed to the repository. ArgoCD will automatically sync the application and deploy the new image to the EKS cluster.**

<img src="https://i.imgur.com/RwMtOPp.png" alt="Result" width="90%">

## <a name="result"></a>Result

1. Python Server: A simple HTTP server running on port 80.
2. Docker Image: Built? test and pushed to Docker Hub using GitHub Actions.
3. If the tests pass, the image is pushed to Docker Hub and the deployment.yml file is updated with the new image tag.
4. EKS Cluster: Created using Terraform.
5. ArgoCD: Installed in the EKS cluster using Helm.
6. Application Deployment: Automatically updated in the EKS cluster using ArgoCD.
7. ArgoCD: Automatically syncs the application and deploys the new image to the EKS cluster.

## <a name="conclusion"></a>Conclusion

This project demonstrates the automation of the CI/CD pipeline using GitHub Actions and ArgoCD. It also provides a practical example of deploying applications to Kubernetes using modern DevOps practices.

## <a name="contributing"></a>Contributing

Contributions are welcome! Please fork the repository and submit a pull request for review.
