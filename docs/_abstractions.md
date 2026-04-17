# Core Abstractions (Draft)

Below are the 8 most important abstractions identified for the Bold Reports Utilities deployment system. These will form the basis of the tutorial chapters.

---

1. **Linux Deployment Scripts**
   - Scripts for installing and uninstalling Bold Reports on Linux systems.
   - *Like a chef preparing and cleaning up a kitchen for a meal.*
   - **Relevant Files:**
     - build/linux/install-boldreports.sh
     - build/linux/uninstall-boldreports.sh

2. **Client Library Installer (Linux)**
   - Script to install optional client libraries for Linux deployments.
   - *Like adding extra ingredients to a recipe as needed.*
   - **Relevant Files:**
     - build/clientlibrary/Linux/install-optional.libs.sh

3. **Docker Single-Container Deployment**
   - Scripts and files for deploying Bold Reports as a single Docker container.
   - *Like packing everything needed for a picnic into one basket.*
   - **Relevant Files:**
     - build/dockerfiles/latest/single-docker-image/

4. **Docker Multi-Container Deployment**
   - Dockerfiles for deploying each Bold Reports service as a separate container.
   - *Like organizing a team where each member has a specific role.*
   - **Relevant Files:**
     - build/dockerfiles/latest/

5. **Kubernetes Deployment**
   - Uses Docker multi-container files for building images and deploying to Kubernetes clusters.
   - *Like orchestrating a concert where each musician (service) plays in harmony.*
   - **Relevant Files:**
     - build/dockerfiles/latest/
     - k8sfiles/

6. **MoveSharedFiles Utility**
   - .NET utility for moving shared files, used in deployment automation.
   - *Like a mover transporting boxes between rooms.*
   - **Relevant Files:**
     - movesharedfiles/MoveSharedFiles/

7. **Client Library Utility (Windows/.NET)**
   - .NET utility for managing client libraries, especially for Windows environments.
   - *Like a librarian organizing books on different shelves.*
   - **Relevant Files:**
     - build/clientlibrary/ClientLibraryUtil/

8. **Entrypoint Scripts**
   - Shell scripts that act as the main entry for various services and containers.
   - *Like the front door to each room in a house, letting you in to start work.*
   - **Relevant Files:**
     - movesharedfiles/MoveSharedFiles/shell_scripts/
     - build/dockerfiles/latest/single-docker-image/entrypoint.sh
     - build/linux/install-boldreports.sh

---

*Next: Relationships and architecture mapping will be documented in the following steps.*
