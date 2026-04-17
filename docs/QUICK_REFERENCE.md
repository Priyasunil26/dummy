# Quick Reference Guide

A concise reference for deploying Bold Reports Utilities across different environments.

---

## Linux Commands

### Installation

```bash
# Install Bold Reports
sudo bash build/linux/install-boldreports.sh \
  --install-dir /var/www/bold-services \
  --user <username> \
  --host-url <your-domain>

# Install client libraries
sudo bash build/clientlibrary/Linux/install-optional.libs.sh
```

### Uninstallation

```bash
# Uninstall Bold Reports
sudo bash build/linux/uninstall-boldreports.sh
```

### Service Management

```bash
# Check service status
sudo systemctl status bold-id-web
sudo systemctl status bold-reports-web

# Restart services
sudo systemctl restart bold-id-web
sudo systemctl restart bold-reports-web

# View logs
sudo journalctl -u bold-reports-web -f
```

---

## Docker Commands

### Single-Container

```bash
# Build
docker build -t boldreports:latest \
  -f build/dockerfiles/latest/single-docker-image/dockerfiles/boldreports-ubuntu.txt \
  build/dockerfiles/latest/single-docker-image/

# Run
docker run -d \
  --name boldreports \
  -p 80:80 \
  -v boldreports-data:/application/app_data \
  -e APP_BASE_URL=http://localhost \
  boldreports:latest

# View logs
docker logs -f boldreports

# Stop
docker stop boldreports

# Remove
docker rm boldreports
```

### Multi-Container

```bash
# Build API service
docker build -t boldreports-api:latest \
  -f build/dockerfiles/latest/boldreports-server-api.txt .

# Build Designer service
docker build -t boldreports-designer:latest \
  -f build/dockerfiles/latest/boldreports-designer.txt .

# Build Jobs service
docker build -t boldreports-jobs:latest \
  -f build/dockerfiles/latest/boldreports-server-jobs.txt .

# Run API service
docker run -d \
  --name boldreports-api \
  -p 8081:80 \
  boldreports-api:latest

# Run Designer service
docker run -d \
  --name boldreports-designer \
  -p 8082:80 \
  boldreports-designer:latest

# Run Jobs service
docker run -d \
  --name boldreports-jobs \
  boldreports-jobs:latest
```

### Docker Compose (Example)

```yaml
version: '3.8'

services:
  boldreports-api:
    image: boldreports-api:latest
    ports:
      - "8081:80"
    volumes:
      - boldreports-data:/application/app_data
    environment:
      - APP_BASE_URL=http://localhost

  boldreports-designer:
    image: boldreports-designer:latest
    ports:
      - "8082:80"
    volumes:
      - boldreports-data:/application/app_data

  boldreports-jobs:
    image: boldreports-jobs:latest
    volumes:
      - boldreports-data:/application/app_data

volumes:
  boldreports-data:
```

---

## Kubernetes Commands

### Build and Push Images

```bash
# Build image
docker build -t your-registry/boldreports-api:latest \
  -f build/dockerfiles/latest/boldreports-server-api.txt .

# Push to registry
docker push your-registry/boldreports-api:latest
```

### Deploy

```bash
# Apply manifests
kubectl apply -f k8sfiles/latest/

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services

# View logs
kubectl logs -f deployment/boldreports-api

# Scale deployment
kubectl scale deployment boldreports-api --replicas=3

# Rollout restart
kubectl rollout restart deployment/boldreports-api
```

### Debugging

```bash
# Describe pod
kubectl describe pod <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- bash

# Port forward for local access
kubectl port-forward svc/boldreports-api 8081:80

# View events
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## Client Library Management

### Linux

```bash
# Install all optional libraries
sudo bash build/clientlibrary/Linux/install-optional.libs.sh

# Verify installation
ls /var/www/bold-services/services/reporting/web/dataextensions/
```

### Windows (PowerShell)

```powershell
# Install optional libraries
.\build\clientlibrary\Azure\install-optional-libs.ps1

# Verify installation
Get-ChildItem "C:\BoldServices\services\reporting\web\dataextensions\"
```

---

## Environment Variables

### Essential Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_BASE_URL` | Base URL for the application | `http://localhost` |
| `BOLD_SERVICES_DB_TYPE` | Database type | `postgresql` |
| `BOLD_SERVICES_DB_HOST` | Database host | `localhost` |
| `BOLD_SERVICES_DB_PORT` | Database port | `5432` |
| `BOLD_SERVICES_DB_USER` | Database user | `boldreports` |
| `BOLD_SERVICES_DB_PASSWORD` | Database password | `password` |
| `BOLD_SERVICES_HOSTING_ENVIRONMENT` | Environment | `Production` |

---

## Configuration Files

### Product Configuration

**Location**: `application/app_data/configuration/product.json`

```json
{
  "InternalAppUrl": {
    "Idp": "http://localhost",
    "Reports": "http://localhost/reporting"
  },
  "BoldProducts": [
    {
      "Name": "BoldReports",
      "Version": "7.1.9"
    }
  ]
}
```

### Nginx Configuration

**Location**: `/etc/nginx/sites-available/boldreports-nginx-config`

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:6500;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /reporting {
        proxy_pass http://localhost:6550;
    }
}
```

---

## Troubleshooting

### Linux

```bash
# Check service status
sudo systemctl status bold-reports-web

# View logs
sudo journalctl -u bold-reports-web -n 100

# Check port usage
sudo netstat -tlnp | grep 80

# Test nginx config
sudo nginx -t
```

### Docker

```bash
# View container logs
docker logs <container-name>

# Inspect container
docker inspect <container-name>

# Check resource usage
docker stats

# Enter container shell
docker exec -it <container-name> bash
```

### Kubernetes

```bash
# Check pod status
kubectl get pods -o wide

# View pod logs
kubectl logs <pod-name>

# Describe pod issues
kubectl describe pod <pod-name>

# Check events
kubectl get events
```

---

## Port Reference

| Service | Default Port |
|---------|-------------|
| Bold ID Web | 6500 |
| Bold ID API | 6501 |
| Bold UMS | 6502 |
| Bold Reports Web | 6550 |
| Bold Reports API | 6551 |
| Bold Reports Jobs | (internal) |
| Bold Reports Viewer | 6553 |
| Bold ETL | 6504 |
| Nginx (HTTP) | 80 |
| Nginx (HTTPS) | 443 |

---

## File Paths

### Linux Installation

| Component | Path |
|-----------|------|
| Installation Directory | `/var/www/bold-services/` |
| Application Data | `/var/www/bold-services/application/app_data/` |
| Configuration | `/var/www/bold-services/application/app_data/configuration/` |
| Logs | `/var/www/bold-services/application/app_data/logs/` |
| Nginx Config | `/etc/nginx/sites-available/boldreports-nginx-config` |
| Systemd Services | `/etc/systemd/system/bold-*.service` |

### Docker Paths

| Component | Path |
|-----------|------|
| Application Root | `/application/` |
| Application Data | `/application/app_data/` |
| Configuration | `/application/app_data/configuration/` |
| Logs | `/application/app_data/logs/` |
| Optional Libraries | `/application/app_data/optional-libs/` |

---

## Database Support

### Supported Databases

- **SQL Server** (built-in)
- **PostgreSQL** (built-in)
- **MySQL** (optional library)
- **Oracle** (optional library)
- **Google BigQuery** (optional library)
- **Snowflake** (optional library)

### Connection String Format

**PostgreSQL**:
```
Host=localhost;Port=5432;Database=boldreports;Username=postgres;Password=password;
```

**MySQL**:
```
Server=localhost;Database=boldreports;User=root;Password=password;
```

**SQL Server**:
```
Server=localhost;Database=boldreports;User Id=sa;Password=password;
```

---

## Version Information

- **Current Version**: 7.1.9
- **IDP Version**: 5.1.1
- **.NET Version**: 8.0
- **Docker Base Image**: mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim

---

## Useful Links

- **[Complete Documentation](index.md)**
- **[Architecture](../architecture.md)**
- **[Tech Stack](../tech-stack.md)**
- **[Tutorials](code-docs/index.md)**

---

*Quick Reference Guide - Last Updated: March 2026*
