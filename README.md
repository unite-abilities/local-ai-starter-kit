# AI Stack: Self-Hosted LLM & Automation Platform

This repository provides a Docker Compose setup to quickly deploy a powerful, self-hosted AI and automation stack on a VPS (or any Linux server). It's designed for flexibility, especially for professional service offerings where clients manage their own LLM API keys.

**Core Applications:**

*   **Caddy:** Automatic HTTPS reverse proxy with SSL certificate management.
*   **PostgreSQL:** Robust relational database serving n8n and OpenWebUI.
*   **n8n:** Workflow automation tool to connect various apps and services.
*   **OpenWebUI:** A user-friendly web interface for interacting with LLMs (similar to ChatGPT).
*   **LiteLLM:** An OpenAI-compatible API proxy that unifies access to various LLM providers (OpenAI, Azure, Anthropic, local models, etc.). Model API keys are managed via its secure Admin UI.
*   **Qdrant:** High-performance vector database for storing and searching embeddings.

## Features

*   **Secure Access:** All services are exposed via HTTPS, managed by Caddy.
*   **Centralized LLM Management:** LiteLLM allows configuration of multiple LLM backends, with API keys managed securely through its own Admin UI using a master key.
*   **Persistent Data:** Docker volumes ensure your data is saved across container restarts.
*   **Optimized Database Usage:** Single PostgreSQL instance for n8n and OpenWebUI.
*   **Scalable Foundation:** Ready for you to expand with more services or local LLMs (e.g., Ollama).

## I. Hostinger VPS Setup & Prerequisites

This guide assumes you're starting with a new Hostinger VPS.

**1. Choose a VPS Plan:**
   *   A plan with at least 2 vCPU, 2GB RAM, and 40GB NVMe SSD should be a good starting point for this stack without running large local LLMs. If you plan to use local models (e.g., via Ollama), you'll need significantly more RAM and potentially GPU resources.
   *   **Operating System:** Choose **Ubuntu 22.04 LTS (or the latest LTS)**. Starting with a minimal/blank OS installation is recommended for better control, though your VPS provider might offer a "Docker pre-installed" option which can save a step if you prefer. This guide will cover manual Docker installation.

**2. Initial Server Setup (Connecting via SSH):**
   *   Once your VPS is provisioned, find its IP address and root password from the VPS panel.
   *   Connect to your server via SSH:
     ```bash
     ssh root@YOUR_SERVER_IP
     ```
   *   You'll be prompted for the root password.

**3. Create a Non-Root User (Security Best Practice):**
```
   bash
   # Replace 'yourusername' with your desired username
   adduser yourusername
   usermod -aG sudo yourusername
   # Log out of root and log back in as the new user
   exit
   ssh yourusername@YOUR_SERVER_IP
```


From now on, perform all commands as yourusername, using sudo when necessary.

##4. Update Your System:

```sudo apt update && sudo apt upgrade -y```

5. Install Docker and Docker Compose:

* Install Docker

```sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker```

* Add your user to the docker group (to run Docker commands without sudo):

``` sudo usermod -aG docker ${USER}
# You need to log out and log back in for this change to take effect.
# Alternatively, you can use 'newgrp docker' in your current session.
newgrp docker ```

Verify by running docker ps (it should not give a permission error).

* Install Docker Compose (v2):
``` sudo apt install -y docker-compose-plugin
# Verify installation
docker compose version ```

(Note: some older systems might use docker-compose (with a hyphen). This setup uses docker compose (space), which is Docker Compose V2, integrated as a Docker plugin.)









