#!/bin/bash

# Magento 2.4.6 Quick Start Script
# This script helps you get started with the installation

echo "=========================================="
echo "  Magento 2.4.6 Docker - Quick Start"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs sudo privileges."
    echo "Please run: sudo ./quickstart.sh"
    exit 1
fi

echo "📋 Pre-installation Checklist:"
echo ""
echo "1. Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo "   ✅ Docker is installed"
    docker --version
else
    echo "   ❌ Docker is not installed"
    echo "   Install with: sudo apt install docker.io"
    exit 1
fi

echo ""
echo "2. Checking Docker service..."
if systemctl is-active --quiet docker; then
    echo "   ✅ Docker service is running"
else
    echo "   ⚠️  Docker service is not running"
    echo "   Starting Docker..."
    systemctl start docker
    sleep 2
fi

echo ""
echo "3. Checking host entry..."
if grep -q "mage246demo.com" /etc/hosts; then
    echo "   ✅ Host entry exists"
else
    echo "   ⚠️  Adding host entry..."
    echo "127.0.0.1   mage246demo.com" >> /etc/hosts
    echo "   ✅ Host entry added"
fi

echo ""
echo "4. Checking Docker containers..."
cd /home/bs01594/Desktop/Magento

# Check if containers are running
RUNNING=$(docker ps --filter "name=m_web247" --format "{{.Names}}" 2>/dev/null)

if [ -z "$RUNNING" ]; then
    echo "   ⚠️  Containers are not running"
    echo "   Starting containers..."
    docker compose up -d 2>&1
    echo ""
    echo "   Waiting for containers to be ready..."
    sleep 10

    # Wait for database
    echo "   Waiting for database to be ready..."
    for i in {1..30}; do
        if docker exec magento_ce_db247 mysqladmin ping -h localhost -u root -proot &> /dev/null; then
            echo "   ✅ Database is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "   ⚠️  Database is taking longer than expected"
        fi
        sleep 1
    done
else
    echo "   ✅ Containers are running"
fi

echo ""
echo "=========================================="
echo "  Container Status"
echo "=========================================="
docker ps --filter "name=m_web247" --filter "name=magento_ce_db247" --filter "name=opensearch_247" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "Your Docker environment is ready! Now you need to install Magento."
echo ""
echo "Option 1: Manual Installation (Recommended for first-time users)"
echo "  Follow the detailed guide:"
echo "  📖 Open: INSTALLATION_GUIDE.md"
echo ""
echo "Option 2: Automated Installation"
echo "  Run: sudo ./install_magento.sh"
echo ""
echo "To access the container and install manually:"
echo "  1. Run: docker exec -it m_web247 bash"
echo "  2. Follow steps in INSTALLATION_GUIDE.md starting from Step 4"
echo ""
echo "=========================================="
echo "  Access URLs"
echo "=========================================="
echo ""
echo "  Frontend:          http://mage246demo.com"
echo "  Admin Panel:       http://mage246demo.com/admin"
echo "  OpenSearch:        http://localhost:9200"
echo "  OpenSearch Dash:   http://localhost:5601"
echo ""
echo "=========================================="
echo ""

# Ask if user wants to access the container
echo "Would you like to access the web container now? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    echo "Accessing container... (type 'exit' to leave)"
    echo ""
    docker exec -it m_web247 bash
fi

echo ""
echo "Done! Happy coding! 🚀"

