# Get Started with Documentation

Welcome! This guide will help you access the comprehensive documentation for Bold Reports Utilities.

---

## 📚 What's Available

Your repository now includes **complete documentation** covering:

- ✅ **8 Tutorial Chapters** - Step-by-step guides from Linux to Kubernetes
- ✅ **Architecture Diagrams** - Visual system design and deployment flows
- ✅ **Tech Stack Details** - All technologies, dependencies, and requirements
- ✅ **Quick Reference** - Commands and configuration for all platforms

---

## 🚀 Quick Start: View Documentation

### Option 1: Interactive (Recommended)

Build and serve the documentation locally with live reload:

```bash
# Install MkDocs and dependencies
pip install mkdocs mkdocs-material pymdown-extensions

# Serve documentation
mkdocs serve

# Open in browser
# http://127.0.0.1:8000/
```

**Benefits**: Interactive navigation, search, dark/light mode, Mermaid diagrams rendered.

---

### Option 2: Read Markdown Files

You can read the documentation directly without building:

1. **Start Here**: [docs/index.md](docs/index.md)
2. **Tutorials**: [docs/index.md](docs/index.md)
3. **Architecture**: [architecture.md](architecture.md)
4. **Tech Stack**: [tech-stack.md](tech-stack.md)

**Benefits**: No build required, works offline, readable in any Markdown viewer.

---

### Option 3: Build Static Site

Generate HTML files for hosting:

```bash
# Build documentation
mkdocs build

# Files generated in site/ directory
cd site
python -m http.server 8000

# Open in browser
# http://127.0.0.1:8000/
```

**Benefits**: Host on any web server, no Python needed after build.

---

## 📖 Documentation Structure

```
docs/
├── 📄 index.md                    # Documentation home
├── 📄 README.md                   # Build instructions
├── 📄 QUICK_REFERENCE.md          # Command reference
│
├── 📂 code-docs/                  # Tutorials
│   ├── 📄 index.md               # Tutorial overview
│   ├── 📄 01_linux_deployment_scripts.md
│   ├── 📄 02_client_library_installer_linux.md
│   ├── 📄 03_entrypoint_scripts.md
│   ├── 📄 04_docker_single_container_deployment.md
│   ├── 📄 05_docker_multi_container_deployment.md
│   ├── 📄 06_kubernetes_deployment.md
│   ├── 📄 07_move_shared_files_utility.md
│   └── 📄 08_client_library_utility_windows.md
│
├── 📂 architecture/               # Architecture docs
│   └── 📄 deployment_architecture.md
│
└── 📂 techstack/                  # Technology stack
    └── 📄 technology_stack.md
```

---

## 🎯 Choose Your Path

### I'm New to Bold Reports Utilities
👉 **Start**: [docs/01_linux_deployment_scripts.md](docs/01_linux_deployment_scripts.md)

Follow the tutorial chapters in order to learn step-by-step.

---

### I Need to Deploy on Linux
👉 **Read**:
- [Chapter 1: Linux Deployment Scripts](docs/01_linux_deployment_scripts.md)
- [Chapter 2: Client Library Installer](docs/02_client_library_installer_linux.md)

👉 **Quick Commands**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

### I Need to Deploy with Docker
👉 **Single-Container**: [Chapter 4](docs/04_docker_single_container_deployment.md)

👉 **Multi-Container**: [Chapter 5](docs/05_docker_multi_container_deployment.md)

👉 **Quick Commands**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

### I Need to Deploy on Kubernetes
👉 **Read**: [Chapter 6: Kubernetes Deployment](docs/06_kubernetes_deployment.md)

👉 **Architecture**: [architecture.md](architecture.md)

---

### I Need Technical Details
👉 **Tech Stack**: [tech-stack.md](tech-stack.md)

👉 **Architecture**: [architecture.md](architecture.md)

---

### I Want Quick Commands
👉 **Quick Reference**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

## 🔍 What's Covered

### Deployment Methods
- ✅ Linux native installation
- ✅ Docker single-container
- ✅ Docker multi-container
- ✅ Kubernetes orchestration

### Utilities
- ✅ Client library management (Linux & Windows)
- ✅ File movement automation
- ✅ Entrypoint scripts
- ✅ Configuration management

### Technical Details
- ✅ Architecture diagrams
- ✅ Technology stack
- ✅ System requirements
- ✅ Database support
- ✅ Port configurations
- ✅ Environment variables

---

## 💡 Key Features

### Beginner-Friendly
- Written for newcomers
- Real-world analogies
- Step-by-step instructions
- Code examples with explanations

### Comprehensive
- All deployment types covered
- Architecture diagrams
- Technical specifications
- Troubleshooting guides

### Interactive
- Live search
- Dark/light mode
- Mermaid diagrams
- Copy code buttons

---

## 🛠️ MkDocs Commands

```bash
# Serve with live reload
mkdocs serve

# Build static site
mkdocs build

# Deploy to GitHub Pages
mkdocs gh-deploy

# Check for errors
mkdocs build --strict
```

---

## 📋 Quick Reference

### Linux Installation
```bash
sudo bash build/linux/install-boldreports.sh
```

### Docker Single-Container
```bash
docker build -t boldreports build/dockerfiles/latest/single-docker-image/
docker run -d --name boldreports -p 80:80 boldreports
```

### Docker Multi-Container
```bash
docker build -t boldreports-api -f build/dockerfiles/latest/boldreports-server-api.txt .
docker run -d --name boldreports-api boldreports-api
```

### Kubernetes
```bash
kubectl apply -f k8sfiles/latest/
kubectl get pods
```

**Full Reference**: [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

## 📦 What's Included

| Document | Purpose |
|----------|---------|
| Tutorial (8 chapters) | Learn how the system works |
| Architecture | Understand system design |
| Tech Stack | Know the technologies |
| Quick Reference | Find commands fast |

---

## 🎓 Learning Path

1. **Read**: [Documentation Home](docs/index.md)
2. **Learn**: [Tutorial Overview](docs/index.md)
3. **Follow**: Chapters 1-8 in order
4. **Reference**: [Quick Reference](docs/QUICK_REFERENCE.md) as needed
5. **Deep Dive**: [Architecture](architecture.md) & [Tech Stack](tech-stack.md)

---

## ✨ Why This Documentation

- ✅ **Beginner-focused** - No prior knowledge needed
- ✅ **Visual** - Architecture diagrams throughout
- ✅ **Practical** - Real code examples
- ✅ **Complete** - All deployment types covered
- ✅ **Searchable** - Find what you need fast

---

## 🚦 Your Next Action

### Ready to build documentation?

```bash
pip install mkdocs mkdocs-material pymdown-extensions
mkdocs serve
```

### Prefer reading directly?

Open [docs/index.md](docs/index.md) in your Markdown viewer or on GitHub.

### Need quick commands?

See [docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)

---

## 📞 Need Help?

- **Documentation Issues**: Edit Markdown files in `docs/`
- **Build Issues**: See [docs/README.md](docs/README.md)
- **Deployment Issues**: See tutorial chapters in `docs/`

---

## 📝 Documentation Summary

- **Total Pages**: 20+
- **Chapters**: 8
- **Diagrams**: 15+
- **Code Examples**: 50+
- **Cross-References**: 30+

**All organized and ready to use!**

---

🎉 **Start exploring**: `mkdocs serve` or [docs/index.md](docs/index.md)

---

*Get Started Guide - March 9, 2026*
