# Step Project 4 - Kubernetes - AWS - ArgoCD

_Tasks_:

1. Create GitHub repo with:

- test python backend server. Just script which listening on some port and respond 200 on /
- Dockerfile with everything needed to run this script
- GitHub action which will build docker image automatically and push to docker hub. Use Github secrets to store your docker hub creds

2. Write terraform code to create EKS cluster

- one node group with one node
- nginx ingress controller

3. Write terraform code which will install ArgoCD to EKS using helm chart or raw k8s manifest

- argocd must have dns name in domain: watashinoheyadesu.pp.ua

4. Write K8S manifests to deploy your app from item 1 to EKS.

- deployment, service, ingress.
- app must be available by dns name in domain: watashinoheyadesu.pp.ua

5. Write ArgoCD app which will deliver code from item 4 to EKS and will update it when new image appeared in docker hub

<br/>
<br/>

## 1. GitHub:

I created a GitHub repository with a simple Python server and a Dockerfile. The server listens on port 80 and responds with status code 200 on `/`.

```python
from http.server import BaseHTTPRequestHandler, HTTPServer

hostName = "0.0.0.0"
serverPort = 80

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/stress":
            # Симуляція навантаження через обчислення фібоначчівих чисел
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
            self.wfile.write(bytes("<h1>STEP 4 UPDATE</h1>", "utf-8"))
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

The Dockerfile is as follows:

```Dockerfile
FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip


WORKDIR /app
COPY . /app

CMD ["python3", "server.py"]
```

I also created a GitHub action to build the Docker image and push it to Docker Hub.

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
  build-and-push:
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

      - name: Build and push Docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: wincchesster/step-4-app:latest, wincchesster/step-4-app:${{ github.sha }}

      - name: Test
        run: |
          docker run --rm -d -p 8080:80 --name test-container wincchesster/step-4-app:latest
          sleep 10 
          response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
          if [ "$response" -ne 200 ]; then
            echo "Test Failed: HTTP response is $response"
            exit 1
          fi

      - name: Cleanup
        run: docker rm -f test-container

      - name: Get the current commit hash
        id: vars
        run: echo "::set-output name=hash::$(git rev-parse HEAD)"

      - name: Update deployment file with the new commit hash
        run: |
          sed -i 's/commit-hash: .*/commit-hash: "'${{ steps.vars.outputs.hash }}'"/' dev/deployment.yml

      - name: Commit and push changes
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add deploy/deployment.yaml
          git commit -m "Update deployment with commit hash"
          git push
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The action is triggered on push to the main branch. It builds the Docker image and pushes it to Docker Hub. It also runs a test to check if the server is working correctly.

> I also added credentials to the GitHub secrets.

## 2. Terraform:

I use the same code from previous lessons to create EKS cluster with one node group and nginx ingress controller.

This is the code for creating ArgoCD using the Helm chart. Also, it created a Route53 record for the ArgoCD server.

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

<img src="https://i.imgur.com/bO5niaQ.png" alt="Result" width="90%">

### Credentials:

After creating the EKS cluster, I need to configure `kubectl` to connect to the cluster.

```bash
aws eks --region eu-central-1 update-kubeconfig --name mycluster --profile default
```

For logging in to the ArgoCD server, I need to get the password.

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

```
argocd login argocd.mycluster.step4.space
```

Add the repository to ArgoCD.

```
argocd repo add https://github.com/wincchesster/step-4-app.git --username <your-github-username> --password <your-personal-access-token>
```

## 3. App for ArgoCD:

I created a K8S manifest to deploy the argoCD to the EKS cluster.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: step-4-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "https://github.com/wincchesster/step-4-app.git"
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

<img src="https://i.imgur.com/Tixb3Vp.png" alt="Result" width="90%">

## Results:

I created a simple Python server, built a Docker image, and pushed it to Docker Hub using GitHub actions. I created an EKS cluster with one node group and an nginx ingress controller. I installed ArgoCD to the EKS cluster using Helm. I created a K8S manifest to deploy the app to the EKS cluster using ArgoCD.

After changing the code in the GitHub repository, the ArgoCD automatically updated the app in the EKS cluster.

<img src="https://i.imgur.com/Nt5pQkK.png" alt="Result" width="90%">

<img src="https://i.imgur.com/bagqd6O.png" alt="Result" width="90%">
