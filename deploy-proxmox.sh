#!/bin/bash
#
# Proxmox LXC Deployment Script for Phonebook Application
# Run this script on your Proxmox host to create and configure the LXC container
#
# Usage: ./deploy-proxmox.sh [container-id] [hostname]
# Example: ./deploy-proxmox.sh 200 phonebook

set -e

# Configuration
CTID="${1:-200}"                           # Container ID
HOSTNAME="${2:-phonebook}"                  # Container hostname
STORAGE="local-lxc"                         # Storage for container root
TEMPLATE="local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"  # Debian 12 template
MEMORY=2048                                 # RAM in MB
SWAP=512                                    # Swap in MB
DISK_SIZE=8                                 # Disk size in GB
CORES=2                                     # CPU cores
NETWORK_BRIDGE="vmbr0"                      # Network bridge
APP_PORT=8000                               # Application port
GITHUB_REPO="https://github.com/matspi/yealink_phonebook.git"  # UPDATE THIS!

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Proxmox LXC Deployment Script${NC}"
echo -e "${GREEN}Phonebook Application${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if running on Proxmox
if ! command -v pct &> /dev/null; then
    echo -e "${RED}Error: This script must be run on a Proxmox host${NC}"
    exit 1
fi

# Check if container already exists
if pct status $CTID &> /dev/null; then
    echo -e "${YELLOW}Warning: Container $CTID already exists${NC}"
    read -p "Do you want to destroy and recreate it? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Stopping and destroying container $CTID..."
        pct stop $CTID 2>/dev/null || true
        pct destroy $CTID
    else
        echo "Aborting."
        exit 1
    fi
fi

echo -e "${GREEN}Creating LXC container...${NC}"
pct create $CTID $TEMPLATE \
    --hostname $HOSTNAME \
    --memory $MEMORY \
    --swap $SWAP \
    --cores $CORES \
    --rootfs $STORAGE:$DISK_SIZE \
    --net0 name=eth0,bridge=$NETWORK_BRIDGE,ip=dhcp \
    --unprivileged 1 \
    --features nesting=1 \
    --onboot 1 \
    --password

echo -e "${GREEN}Starting container...${NC}"
pct start $CTID

# Wait for container to be ready
echo "Waiting for container to boot..."
sleep 5

echo -e "${GREEN}Updating system packages...${NC}"
pct exec $CTID -- bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"

echo -e "${GREEN}Installing required packages...${NC}"
pct exec $CTID -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    sqlite3 \
    systemd"

echo -e "${GREEN}Creating application user...${NC}"
pct exec $CTID -- bash -c "useradd -m -s /bin/bash phonebook || true"

echo -e "${GREEN}Creating application directory...${NC}"
pct exec $CTID -- bash -c "mkdir -p /opt/phonebook /opt/phonebook/data && chown -R phonebook:phonebook /opt/phonebook"

echo -e "${GREEN}Cloning application from GitHub...${NC}"
echo -e "${YELLOW}Make sure to update GITHUB_REPO variable in this script!${NC}"
pct exec $CTID -- bash -c "cd /opt/phonebook && sudo -u phonebook git clone $GITHUB_REPO app"

echo -e "${GREEN}Setting up Python virtual environment...${NC}"
pct exec $CTID -- bash -c "cd /opt/phonebook/app && sudo -u phonebook python3 -m venv venv"

echo -e "${GREEN}Installing Python dependencies...${NC}"
pct exec $CTID -- bash -c "cd /opt/phonebook/app && sudo -u phonebook venv/bin/pip install --upgrade pip && sudo -u phonebook venv/bin/pip install -r backend/requirements.txt"

echo -e "${GREEN}Creating systemd service...${NC}"
pct exec $CTID -- bash -c 'cat > /etc/systemd/system/phonebook.service << EOF
[Unit]
Description=Phonebook Application
After=network.target

[Service]
Type=simple
User=phonebook
Group=phonebook
WorkingDirectory=/opt/phonebook/app
Environment="DATABASE_URL=sqlite:////opt/phonebook/data/phonebook.db"
ExecStart=/opt/phonebook/app/venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

echo -e "${GREEN}Creating update script...${NC}"
pct exec $CTID -- bash -c 'cat > /usr/local/bin/update << "EOF"
#!/bin/bash
#
# Update script for Phonebook application
# Pulls latest code from GitHub and restarts the service
#

set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Phonebook Application Update${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

APP_DIR="/opt/phonebook/app"
BACKUP_DIR="/opt/phonebook/backups"
BACKUP_NAME="phonebook-$(date +%Y%m%d-%H%M%S).db"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Backup database
echo -e "${GREEN}Backing up database...${NC}"
mkdir -p "$BACKUP_DIR"
if [ -f "/opt/phonebook/data/phonebook.db" ]; then
    cp "/opt/phonebook/data/phonebook.db" "$BACKUP_DIR/$BACKUP_NAME"
    echo -e "${GREEN}Database backed up to: $BACKUP_DIR/$BACKUP_NAME${NC}"

    # Keep only last 10 backups
    cd "$BACKUP_DIR"
    ls -t phonebook-*.db | tail -n +11 | xargs -r rm
fi

# Stop service
echo -e "${GREEN}Stopping phonebook service...${NC}"
systemctl stop phonebook

# Pull latest code
echo -e "${GREEN}Pulling latest code from GitHub...${NC}"
cd "$APP_DIR"
sudo -u phonebook git fetch --all
sudo -u phonebook git reset --hard origin/main || sudo -u phonebook git reset --hard origin/master

# Update dependencies
echo -e "${GREEN}Updating Python dependencies...${NC}"
sudo -u phonebook venv/bin/pip install --upgrade pip
sudo -u phonebook venv/bin/pip install -r backend/requirements.txt

# Start service
echo -e "${GREEN}Starting phonebook service...${NC}"
systemctl start phonebook

# Check status
sleep 2
if systemctl is-active --quiet phonebook; then
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}Update completed successfully!${NC}"
    echo -e "${GREEN}======================================${NC}"
    systemctl status phonebook --no-pager
else
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}Error: Service failed to start${NC}"
    echo -e "${RED}======================================${NC}"
    echo -e "${YELLOW}Restoring database backup...${NC}"
    cp "$BACKUP_DIR/$BACKUP_NAME" "/opt/phonebook/data/phonebook.db"
    systemctl start phonebook
    exit 1
fi
EOF'

pct exec $CTID -- chmod +x /usr/local/bin/update

echo -e "${GREEN}Enabling and starting phonebook service...${NC}"
pct exec $CTID -- systemctl daemon-reload
pct exec $CTID -- systemctl enable phonebook
pct exec $CTID -- systemctl start phonebook

# Wait for service to start
sleep 3

# Get container IP
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Container ID: ${GREEN}$CTID${NC}"
echo -e "Hostname: ${GREEN}$HOSTNAME${NC}"
echo -e "IP Address: ${GREEN}$CONTAINER_IP${NC}"
echo -e "Application URL: ${GREEN}http://$CONTAINER_IP:$APP_PORT${NC}"
echo ""
echo -e "${YELLOW}To update the application in the future:${NC}"
echo -e "  pct exec $CTID -- update"
echo -e "  ${GREEN}or${NC}"
echo -e "  Enter the container: ${GREEN}pct enter $CTID${NC}"
echo -e "  Run update script: ${GREEN}update${NC}"
echo ""
echo -e "${YELLOW}To check service status:${NC}"
echo -e "  pct exec $CTID -- systemctl status phonebook"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo -e "  pct exec $CTID -- journalctl -u phonebook -f"
echo ""
echo -e "${GREEN}Don't forget to update the GITHUB_REPO variable in this script!${NC}"
echo ""
