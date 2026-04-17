# Project Summary and Relationships

**Project Summary:**

**Bold Reports Utilities** is a deployment toolkit for Bold Reports, supporting Linux, Docker (single/multi-container), and Kubernetes environments. It provides scripts and utilities to automate installation, configuration, and management of services and client libraries, making deployment flexible and efficient for different infrastructures.

---

## Key Relationships

| Source Abstraction           | Target Abstraction                | Relationship Label         |
|-----------------------------|-----------------------------------|---------------------------|
| Linux Deployment Scripts     | Entrypoint Scripts                | Uses                      |
| Linux Deployment Scripts     | Client Library Installer (Linux)  | Invokes                   |
| Docker Single-Container     | Entrypoint Scripts                | Uses                      |
| Docker Multi-Container      | Entrypoint Scripts                | Uses                      |
| Kubernetes Deployment       | Docker Multi-Container Deployment | Uses                      |
| MoveSharedFiles Utility     | Entrypoint Scripts                | Supports                  |
| Client Library Utility      | Client Library Installer (Linux)  | Supports                  |
| Entrypoint Scripts          | MoveSharedFiles Utility           | Invokes                   |

---

**Every abstraction is connected to at least one other, forming a cohesive deployment system.**

*Next: Chapters will be ordered for a progressive learning experience.*
