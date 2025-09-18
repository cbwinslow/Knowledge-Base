#!/bin/bash

# Getting Started with Immediate Next Steps
# This script guides you through the immediate next steps to complete your security setup

echo "=== Getting Started with Immediate Next Steps ==="
echo ""

# Display current date and time
echo "Report generated on: $(date)"
echo ""

# Check current status
echo "Current Status Check:"
echo "==================="
echo ""

# Check if Nextcloud files are available
if [ -d "/tmp/nextcloud" ]; then
    echo "✅ Nextcloud files: Available in /tmp/nextcloud"
else
    echo "❌ Nextcloud files: Not found"
fi

# Check if required services are running
SERVICES=("apache2" "postgresql")
STOPPED_SERVICES=()

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
        STOPPED_SERVICES+=("$service")
    fi
done

echo ""
echo "Immediate Next Steps:"
echo "==================="
echo ""

# Step 1: Deploy Nextcloud
echo "Step 1: Deploy Nextcloud"
echo "-----------------------"
if [ -d "/tmp/nextcloud" ]; then
    echo "Nextcloud files are available in /tmp/nextcloud"
    echo "Run the deployment script to install Nextcloud:"
    echo ""
    echo "   /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
    echo ""
    echo "This will:"
    echo "1. Move Nextcloud files to /var/www/nextcloud"
    echo "2. Set proper ownership for Nextcloud files"
    echo "3. Create Nextcloud configuration files"
    echo "4. Restart Apache to apply changes"
    echo ""
else
    echo "❌ Nextcloud files not found in /tmp/nextcloud"
    echo "Please ensure Nextcloud files are in /tmp/nextcloud before proceeding"
    echo ""
fi

# Step 2: Start required services
echo "Step 2: Start Required Services"
echo "------------------------------"
if [ ${#STOPPED_SERVICES[@]} -gt 0 ]; then
    echo "The following services need to be started:"
    for service in "${STOPPED_SERVICES[@]}"; do
        echo "   sudo systemctl start $service"
    done
    echo ""
else
    echo "✅ All required services are already running"
    echo ""
fi

# Step 3: Configure Cloudflare Tunnel
echo "Step 3: Configure Cloudflare Tunnel"
echo "----------------------------------"
echo "Follow the manual setup instructions in:"
echo "   /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo ""
echo "This will:"
echo "1. Replace placeholder certificate with actual Cloudflare certificate"
echo "2. Create tunnel for nextcloud"
echo "3. Configure tunnel routing for cloudcurio.cc"
echo "4. Start tunnel service"
echo "5. Test external access at https://cloudcurio.cc/nextcloud"
echo ""

# Step 4: Access Nextcloud
echo "Step 4: Access Nextcloud"
echo "-----------------------"
echo "After deploying Nextcloud, access it at:"
echo "   Local: http://localhost/nextcloud"
echo "   External (after Cloudflare Tunnel setup): https://cloudcurio.cc/nextcloud"
echo ""
echo "Complete the initial web-based setup wizard to create your admin account."
echo ""

# Documentation and resources
echo "Documentation and Resources:"
echo "=========================="
echo ""
echo "Main documentation directory:"
echo "   /home/cbwinslow/security_setup/docs/"
echo ""
echo "Key documents:"
echo "   - final_next_steps_summary.md: Complete next steps summary"
echo "   - security_setup_roadmap.md: Detailed roadmap"
echo "   - core_components_verification.md: Core components verification"
echo "   - manual_cloudflare_tunnel_cloudcurio.md: Manual Cloudflare Tunnel setup"
echo ""
echo "Scripts directory:"
echo "   /home/cbwinslow/security_setup/"
echo ""
echo "Key scripts:"
echo "   - deploy_nextcloud_simple.sh: Nextcloud deployment script"
echo "   - verify_core_components.sh: Core components verification script"
echo "   - troubleshoot.sh: Troubleshooting script"
echo ""

# Summary
echo "Summary:"
echo "======="
echo ""
echo "Your security setup is well underway with a solid foundation established."
echo "The immediate priorities are:"
echo "1. Completing the Nextcloud deployment"
echo "2. Starting required services (Apache, PostgreSQL)"
echo "3. Configuring Cloudflare Tunnel for secure external access"
echo ""
echo "Once these are complete, you can proceed with configuring the monitoring"
echo "tools and eventually installing the threat intelligence and penetration"
echo "testing platforms."
echo ""
echo "All necessary scripts and documentation are in place to guide you through"
echo "the remaining steps. The modular approach of your setup allows you to"
echo "complete components at your own pace based on your priorities and requirements."
echo ""
echo "For any issues or questions, refer to the documentation in"
echo "/home/cbwinslow/security_setup/docs/ or run the troubleshooting script at"
echo "/home/cbwinslow/security_setup/troubleshoot.sh."
echo ""
echo "Happy securing!"