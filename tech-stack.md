# Technology Stack

This document provides a comprehensive overview of the technologies, languages, frameworks, and dependencies used in the Bold Reports Utilities deployment system.

---

## Summary

The Bold Reports Utilities system is built with a diverse technology stack to support flexible deployment across Linux, Docker, and Kubernetes environments. The core technologies include:

- **Shell Scripting** (Bash) for Linux automation
- **.NET 8.0** for cross-platform utilities
- **Docker** for containerization
- **Kubernetes** for orchestration
- **Nginx** for web server and reverse proxy
- **JSON** for configuration management

---

## Programming Languages

### 1. **Bash (Shell Scripting)**

**Usage**: Primary automation language for Linux deployments and container entrypoints

**Version**: Bash 4.0+

**Key Files**:
- `build/linux/install-boldreports.sh`
- `build/linux/uninstall-boldreports.sh`
- `build/clientlibrary/Linux/install-optional.libs.sh`
- `build/dockerfiles/latest/single-docker-image/entrypoint.sh`
- `movesharedfiles/MoveSharedFiles/shell_scripts/*/entrypoint.sh`

**Purpose**:
- System installation and configuration
- Service initialization
- Environment setup
- Container orchestration

---

### 2. **C# (.NET 8.0)**

**Usage**: Utility programs for file management and client library configuration

**Version**: .NET 8.0 (LTS)

**Key Projects**:

#### MoveSharedFiles
- **Location**: `movesharedfiles/MoveSharedFiles/`
- **Purpose**: Automated file movement during deployment
- **Dependencies**: Newtonsoft.Json 13.0.3

#### ClientLibraryUtil
- **Location**: `build/clientlibrary/ClientLibraryUtil/`
- **Purpose**: Update data extensions and client library configurations
- **Dependencies**: Newtonsoft.Json 13.0.3

**Why .NET 8.0?**
- Cross-platform support (Linux, Windows, macOS)
- High performance
- Long-term support
- Modern C# language features

---

### 3. **PowerShell**

**Usage**: Windows-specific client library installation

**Version**: PowerShell 5.1+ / PowerShell Core 7+

**Key Files**:
- `build/clientlibrary/Azure/install-optional-libs.ps1`

**Purpose**:
- Azure and Windows deployment automation
- Client library management on Windows systems

---

## Infrastructure Technologies

### 1. **Docker**

**Version**: Docker 20.10+ recommended

**Base Images**:
- `mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim` - Debian-based ASP.NET runtime
- Ubuntu variants (18.04, 20.04, 22.04)
- Debian variants (Buster, Bullseye, Bookworm)
- Alpine Linux (minimal footprint)

**Architecture Support**:
- AMD64 (x86_64)
- ARM64 (aarch64)

**Dockerfile Locations**:
- Single-container: `build/dockerfiles/latest/single-docker-image/dockerfiles/`
- Multi-container: `build/dockerfiles/latest/*.txt`

---

### 2. **Kubernetes**

**Version**: Kubernetes 1.20+

**Manifest Locations**:
- `k8sfiles/*_release/`

**Kubernetes Resources Used**:
- Deployments
- Services
- ConfigMaps
- PersistentVolumeClaims
- Ingress (optional)

**Container Orchestration**:
- Pod management
- Service discovery
- Load balancing
- Auto-scaling
- Rolling updates

---

### 3. **Nginx**

**Version**: Nginx 1.18+

**Configuration Files**:
- `build/linux/boldreports-nginx-config`
- `installscripts/boldreports-nginx-config`

**Purpose**:
- Web server
- Reverse proxy
- SSL/TLS termination
- Load balancing

**Features**:
- HTTP/HTTPS support
- WebSocket proxying
- Custom routing for Bold Reports services

---

## System Dependencies

### Linux Packages

The Dockerfiles and installation scripts install the following system packages:

#### Core Dependencies
- `fontconfig` - Font configuration
- `libgdiplus` - GDI+ compatibility for .NET
- `zip` / `unzip` - Archive management
- `curl` / `wget` - HTTP clients
- `git` - Version control

#### Monitoring & Utilities
- `nano` - Text editor
- `procps` - Process utilities
- `jq` - JSON processor
- `iputils-ping` - Network utilities

#### Graphics & Rendering (for report generation)
- `xvfb` - Virtual framebuffer
- `gconf-service` - GNOME configuration
- `libasound2` - Audio library
- `libatk1.0-0` - Accessibility toolkit
- `libcairo2` - 2D graphics library
- `libcups2` - Printing support
- `libgdk-pixbuf2.0-0` - Image loading
- `libgtk-3-0` - GTK+ 3 toolkit
- `libnss3` - Network security services
- `libx11-*` - X11 libraries
- `fonts-liberation` - Liberation fonts

#### Puppeteer Dependencies (for PDF generation)
- Chromium dependencies for headless browser rendering

---

## Database Client Libraries

### Supported Databases

The system supports optional client libraries for:

#### 1. **MySQL**
- Library: `MySqlConnector.dll`
- Provider: MySqlConnector (ADO.NET)

#### 2. **PostgreSQL**
- Library: `Npgsql.dll`
- Provider: Npgsql (official PostgreSQL driver for .NET)

#### 3. **Oracle**
- Library: `Oracle.ManagedDataAccess.dll`
- Provider: Oracle Managed Data Access (official Oracle driver)

#### 4. **Google BigQuery**
- Library: `BoldReports.Data.GoogleBigQuery.dll`
- Dependencies: Google Cloud BigQuery client libraries
  - `Google.Cloud.BigQuery.V2.dll`
  - `Google.Apis.Bigquery.v2.dll`
  - `Google.Apis.Core.dll`
  - `Google.Apis.dll`
  - `Google.Api.Gax.dll`
  - `Google.Api.Gax.Rest.dll`

#### 5. **Snowflake**
- Library: `Snowflake.Data.dll`
- Provider: Snowflake .NET connector

---

## Configuration Formats

### 1. **JSON**

**Primary Configuration Format**

**Key Files**:
- `product.json` - Product version and internal URLs
- `*.deps.json` - .NET dependency manifests
- `*.runtimeconfig.json` - .NET runtime configurations

**Example**: `product.json`
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

---

### 2. **XML**

**Used For**: Legacy configuration files

**Key Files**:
- `config.xml` - Application configuration

---

### 3. **Plain Text**

**Used For**: Dockerfile definitions and consent files

**Examples**:
- `boldreports-server.txt` - Docker image definition
- `consent-to-deploy-client-libraries.txt` - License consent
- `optional-libs.txt` - Optional library manifest

---

## .NET Dependencies

### NuGet Packages

#### Newtonsoft.Json (13.0.3)
- **Purpose**: JSON serialization/deserialization
- **Usage**: Configuration management, data processing
- **Used By**: Both MoveSharedFiles and ClientLibraryUtil

---

## Development Tools

### Build System

- **.NET CLI** - For building C# utilities
- **Docker CLI** - For building container images
- **kubectl** - For Kubernetes deployments

### Version Control

- **Git** - Source control

---

## Runtime Requirements

### Linux Deployment

| Component | Version |
|-----------|---------|
| Operating System | Ubuntu 18.04+, Debian 10+, RHEL 8+ |
| .NET Runtime | 8.0 |
| Nginx | 1.18+ |
| Bash | 4.0+ |
| systemd | 232+ |

### Docker Deployment

| Component | Version |
|-----------|---------|
| Docker Engine | 20.10+ |
| Docker Compose | 2.0+ (for multi-container) |
| Base Image OS | Debian Bookworm / Ubuntu / Alpine |
| .NET Runtime | 8.0 (included in images) |

### Kubernetes Deployment

| Component | Version |
|-----------|---------|
| Kubernetes | 1.20+ |
| kubectl | Matching K8s version |
| Container Runtime | Docker / containerd |
| Storage | CSI-compatible storage |

---

## Ports & Networking

### Default Ports

| Service | Port |
|---------|------|
| Bold ID Web | 80/443 |
| Bold ID API | 80 |
| Bold UMS | 80 |
| Bold Reports Web | 80 |
| Bold Reports API | 80 |
| Bold Reports Viewer | 80 |
| Bold Reports Jobs | (internal) |
| Bold ETL | (internal) |

**Note**: Services are typically reverse-proxied through Nginx on port 80/443.

---

## Environment Variables

### Key Environment Variables Used

- `APP_BASE_URL` - Base URL for the application
- `BOLD_SERVICES_HOSTING_ENVIRONMENT` - Hosting environment (Production/Development)
- Database connection strings (varies by deployment)
- SSL certificate paths
- Custom application settings

---

## Security Technologies

- **SSL/TLS** - HTTPS encryption
- **systemd** - Linux service management and isolation
- **Docker security** - Container isolation
- **Kubernetes RBAC** - Role-based access control
- **Environment-based secrets** - Secure configuration management

---

## Monitoring & Logging

- **systemd journal** - Linux service logs
- **Docker logs** - Container stdout/stderr
- **Kubernetes logs** - Pod logs via kubectl
- **Application logs** - Stored in `app_data` directories

---

## Platform Support

### Operating Systems

| OS | Linux Native | Docker | Kubernetes |
|----|--------------|--------|------------|
| Ubuntu 18.04+ | ✅ | ✅ | ✅ |
| Debian 10+ | ✅ | ✅ | ✅ |
| RHEL/CentOS 8+ | ✅ | ✅ | ✅ |
| Alpine Linux | ❌ | ✅ | ✅ |
| Windows Server | ⚠️ (limited) | ⚠️ (limited) | ✅ |

### Architectures

- **AMD64 (x86_64)** - Full support
- **ARM64 (aarch64)** - Full support (Docker & Kubernetes)

---

## Version History

### Current Version
- **Bold Reports**: 7.1.9
- **IDP Version**: 5.1.1
- **.NET**: 8.0

### Versioned Releases
- 12.1, 11.1, 10.1, 9.1, 8.1, 7.1, 6.3, 6.2, 6.1, 5.4, 5.3, 5.2, 5.1, 4.2

Each version maintains its own Docker and Kubernetes configurations for stability and backward compatibility.

---

## Future Technologies (Potential)

- **Helm Charts** - Kubernetes package management
- **Terraform** - Infrastructure as Code
- **Ansible** - Configuration management
- **Prometheus/Grafana** - Monitoring and metrics
- **ELK Stack** - Centralized logging

---

*This technology stack is designed for robustness, scalability, and compatibility across diverse deployment environments.*
