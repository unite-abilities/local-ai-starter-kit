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

This guide assumes you're starting with a new VPS.

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

**4. Update Your System:**

```sudo apt update && sudo apt upgrade -y```

**5. Install Docker and Docker Compose:**

* Install Docker

```
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
```

* Add your user to the docker group (to run Docker commands without sudo):

```
sudo usermod -aG docker ${USER}
# You need to log out and log back in for this change to take effect.
# Alternatively, you can use 'newgrp docker' in your current session.
newgrp docker
```

Verify by running docker ps (it should not give a permission error).

* Install Docker Compose (v2):
```
sudo apt install -y docker-compose-plugin
# Verify installation
docker compose version
```

(Note: some older systems might use docker-compose (with a hyphen). This setup uses docker compose (space), which is Docker Compose V2, integrated as a Docker plugin.)

**6. Install Git (if not already installed):**
```
sudo apt install -y git
```

**7. Configure Firewall (UFW - Uncomplicated Firewall):**
* Allow SSH, HTTP, and HTTPS:
```
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp  # HTTP for Caddy's ACME challenge
sudo ufw allow 443/tcp # HTTPS for Caddy
sudo ufw allow 443/udp # For HTTP/3 with Caddy
sudo ufw enable
sudo ufw status
```
* Answer y to proceed with enabling the firewall.

**8. DNS Setup:**

* Before proceeding, ensure you have DNS A records pointing your desired domains (e.g., n8n.yourdomain.com, webui.yourdomain.com, litellm.yourdomain.com) to your VPS's public IP address. This is crucial for Caddy to obtain SSL certificates.

## II. Deploying the AI Stack

**1. Clone This Repository:**

```
git clone <URL_OF_YOUR_GITHUB_REPO> hostinger-ai-stack
cd hostinger-ai-stack
```
**2. Configure Environment Variables:**
Copy the example environment file:
```
cp .env.example .env
```
* Edit the .env file with your specific details using a text editor like nano:
```
nano .env
```

Critical variables to update:
* TZ: Your server's timezone (e.g., America/New_York, Europe/London).
* CADDY_ADMIN_EMAIL: Your email address for Let's Encrypt SSL registration.
* N8N_DOMAIN, OPENWEBUI_DOMAIN, LITELLM_DOMAIN, QDRANT_DOMAIN: Your actual domain names.
* POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, OPENWEBUI_DB_NAME: Update if you want custom database credentials/names.
* N8N_ENCRYPTION_KEY: Generate a strong random key. Use: openssl rand -hex 32
* N8N_BASIC_AUTH_USER, N8N_BASIC_AUTH_PASSWORD: Optional, for basic authentication on n8n.
* LITELLM_MASTER_KEY: Generate a strong random key. Use: openssl rand -hex 32. This key secures the LiteLLM Admin UI.
* PUID and PGID: Set these to your host user's ID to avoid permission issues with mounted volumes.
  * Run id -u yourusername (replace yourusername with the non-root user you created) to get PUID.
  * Run id -g yourusername to get PGID.
  * (Commonly 1000 for both if it's the first user created).
 

**3. Review Caddy Configuration (Caddyfile):**
* The Caddyfile uses environment variables from .env for domain names. Usually, no changes are needed here if .env is correctly configured.

**4. Review LiteLLM Configuration Template (litellm_config.yaml):**
* The litellm_config.yaml file provides a template for models.
* API keys and specific model configurations will be managed via the LiteLLM Admin UI after deployment.
* You can add more model "templates" to this file if you want them to appear as pre-filled options in the UI.

**5. Make PostgreSQL Init Script Executable:**
```
chmod +x postgres-init/init-dbs.sh
```
**6. Start the Stack:**
Ensure you are in the hostinger-ai-stack directory.
```
docker compose up -d
```
This command will download the Docker images (if not present locally) and start all the services in detached mode (-d).

**7. Initial Startup & SSL Certificates:**

The first time Caddy starts, it will attempt to obtain SSL certificates for your configured domains. This might take a few minutes.
You can monitor the logs of Caddy to see this process:
```
docker compose logs -f caddy
```
* Once successful, Caddy will serve your applications over HTTPS.


## III. Accessing and Configuring Services

1. Accessing Services:
* n8n: https://<YOUR_N8N_DOMAIN>
* OpenWebUI: https://<YOUR_OPENWEBUI_DOMAIN>
* LiteLLM API Endpoint: https://<YOUR_LITELLM_DOMAIN> (e.g., for API calls)
* LiteLLM Admin UI: https://<YOUR_LITELLM_DOMAIN>/ui (or try https://<YOUR_LITELLM_DOMAIN>/)
* Qdrant Web UI (if proxied by Caddy): https://<YOUR_QDRANT_DOMAIN>
* Qdrant HTTP API is also available at http://localhost:6333 on the VPS itself (or proxied via Caddy).

**2. LiteLLM Model Configuration (Crucial Step):**
LiteLLM is your central gateway to various LLM providers. Configure it via its Admin UI:

* Navigate: Open https://<YOUR_LITELLM_DOMAIN>/ui in your browser.
* Authenticate: You'll be prompted for the Master Key. Enter the LITELLM_MASTER_KEY value from your .env file.
* Configure Models:
  * You'll see an interface to manage the configuration (which reflects litellm_config.yaml).
  * The model "templates" from litellm_config.yaml (e.g., gpt-3.5-turbo) will appear.
  * To enable a model: Click to edit it, add the necessary API key (e.g., api_key: "sk-..." for OpenAI), and any other provider-specific parameters (like api_base for Azure OpenAI).
  * You can add completely new models not in the template.
  * Save Changes: Click the "Update Config" or similar button in the UI. This writes changes back to the litellm_config.yaml file on your server, making them persistent.

**3. OpenWebUI Setup:**

* When you first access OpenWebUI, create an admin account.
* OpenWebUI is configured to use LiteLLM as its backend (OPENAI_API_BASE_URL: "http://litellm:4000/v1").
* The models available in OpenWebUI will be those successfully configured and active in LiteLLM.
* In OpenWebUI settings, you might need to "Reload Models" or refresh the page after configuring LiteLLM.
* Select a model from the dropdown to start chatting. If no models appear, double-check your LiteLLM configuration and logs.

**4. n8n Setup:**

* On first access to n8n, you'll be prompted to create an owner account.
* If you configured N8N_BASIC_AUTH_USER and N8N_BASIC_AUTH_PASSWORD in .env, you'll need those credentials first.

## IV. Managing the Stack

* View Logs for All Services:
```
docker compose logs -f
```
**- View Logs for a Specific Service:**
```
docker compose logs -f <service_name> 
# e.g., docker compose logs -f litellm
```

**- Stop All Services:**
```
docker compose down
```

**- Stop and Remove Volumes (WARNING: Deletes all data like databases, n8n workflows, etc.):**
```
docker compose down -v
```

**- Restart Services:**
```
docker compose restart <service_name> # Restart specific service
docker compose restart # Restart all services
```

**- Update Services (Pull newer Docker images and recreate containers):**
```
docker compose pull # Pulls the latest images defined in docker-compose.yml
docker compose up -d --remove-orphans # Recreates containers with new images
```




