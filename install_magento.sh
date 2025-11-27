#!/bin/bash

echo "================================"
echo "Magento 2.4.6 Installation Script"
echo "================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./install_magento.sh"
    exit 1
fi

# Check if containers are running
echo "Checking Docker containers..."
docker ps | grep m_web247 || { echo "Error: m_web247 container is not running"; exit 1; }
docker ps | grep magento_ce_db247 || { echo "Error: magento_ce_db247 container is not running"; exit 1; }
docker ps | grep opensearch_247 || { echo "Error: opensearch_247 container is not running"; exit 1; }

echo "All containers are running!"
echo ""

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 5

# Check if vendor directory and autoload file exist
echo "Checking if composer dependencies are installed..."
if ! docker exec m_web247 test -f /var/www/html/vendor/autoload.php; then
    echo "Composer dependencies not found. Installing..."
    docker exec m_web247 bash -c "cd /var/www/html && composer install --no-interaction"

    # Verify installation succeeded
    if ! docker exec m_web247 test -f /var/www/html/vendor/autoload.php; then
        echo "✗ Error: Composer install failed!"
        echo "Running composer install with verbose output for debugging..."
        docker exec m_web247 bash -c "cd /var/www/html && composer install -vvv"
        exit 1
    fi
    echo "✓ Composer dependencies installed successfully!"
else
    echo "✓ Composer dependencies already installed. Skipping..."
fi

# Set proper permissions
echo "Setting proper permissions..."
docker exec m_web247 bash -c "chmod -R 777 /var/www/html"

# Check if Magento is already installed
if docker exec m_web247 test -f /var/www/html/app/etc/env.php; then
    echo "Magento appears to be already installed!"
    echo "Checking installation..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento --version"
    echo ""
    echo "Reindexing all indexers..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento indexer:reindex"
    echo ""
    echo "If you want to reinstall, please delete app/etc/env.php and app/etc/config.php first"
    exit 0
fi

# Install Magento
echo "Installing Magento 2.4.6..."
docker exec m_web247 bash -c "cd /var/www/html && bin/magento setup:install \
  --base-url=http://mage246demo.com \
  --db-host=magento_ce_db247 \
  --db-name=magento \
  --db-user=root \
  --db-password=root \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password=admin123 \
  --language=en_US \
  --currency=USD \
  --timezone=Asia/Dhaka \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch_247 \
  --opensearch-port=9200 \
  --opensearch-index-prefix=magento2 \
  --opensearch-timeout=15 \
  --backend-frontname=admin"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Magento installation completed successfully!"
    echo ""

    # Compile dependency injection (generate interceptor classes)
    echo "Compiling dependency injection and generating code..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento setup:di:compile"

    # Deploy static content
    echo "Deploying static content..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento setup:static-content:deploy -f"

    # Set proper permissions again
    echo "Setting final permissions..."
    docker exec m_web247 bash -c "chmod -R 777 /var/www/html/var /var/www/html/generated /var/www/html/pub/static"

    # Disable 2FA for admin (optional, for easier local development)
    echo "Disabling 2FA for admin (local development)..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth"

    # Reindex all indexers
    echo "Reindexing all indexers..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento indexer:reindex"

    # Flush cache
    echo "Flushing cache..."
    docker exec m_web247 bash -c "cd /var/www/html && bin/magento cache:flush"

    echo ""
    echo "================================"
    echo "✓ Installation Complete!"
    echo "================================"
    echo ""
    echo "Frontend: http://mage246demo.com"
    echo "Admin Panel: http://mage246demo.com/admin"
    echo "Admin Username: admin"
    echo "Admin Password: admin123"
    echo ""
    echo "OpenSearch: http://localhost:9200"
    echo "OpenSearch Dashboards: http://localhost:5601"
    echo ""
else
    echo ""
    echo "✗ Magento installation failed!"
    echo "Please check the error messages above."
    exit 1
fi
