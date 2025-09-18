#!/bin/bash

# Quick Readiness Check for Phase 2
# This script checks if everything is ready to move to Phase 2 of the security setup

echo "=== Quick Readiness Check for Phase 2 ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Quick Readiness Check for Phase 2"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Readiness Check Results"
    echo ""
} > $DOCS_DIR/phase2_readiness_check.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/phase2_readiness_check.md
}

echo "Checking readiness for Phase 2 of your security setup..."
log_action "Checking readiness for Phase 2 of your security setup"

# Track readiness status
READY_FOR_PHASE2=true

# 1. Check if core infrastructure is ready
echo ""
echo "1. Checking core infrastructure readiness..."
log_action "1. Checking core infrastructure readiness..."

# Check SSH
if systemctl is-active --quiet ssh; then
    echo "✅ SSH: Ready"
    log_action "✅ SSH: Ready"
else
    echo "❌ SSH: Not ready"
    log_action "❌ SSH: Not ready"
    READY_FOR_PHASE2=false
fi

# Check Docker
if systemctl is-active --quiet docker; then
    echo "✅ Docker: Ready"
    log_action "✅ Docker: Ready"
else
    echo "❌ Docker: Not ready"
    log_action "❌ Docker: Not ready"
    READY_FOR_PHASE2=false
fi

# Check Apache
if systemctl is-active --quiet apache2; then
    echo "✅ Apache: Ready"
    log_action "✅ Apache: Ready"
else
    echo "⚠️  Apache: Not running (can be started when needed)"
    log_action "⚠️  Apache: Not running (can be started when needed)"
fi

# Check PHP
if command -v php &> /dev/null; then
    echo "✅ PHP: Ready"
    log_action "✅ PHP: Ready"
else
    echo "❌ PHP: Not ready"
    log_action "❌ PHP: Not ready"
    READY_FOR_PHASE2=false
fi

# Check PostgreSQL
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL: Ready"
    log_action "✅ PostgreSQL: Ready"
else
    echo "⚠️  PostgreSQL: Not running (can be started when needed)"
    log_action "⚠️  PostgreSQL: Not running (can be started when needed)"
fi

# Check Fail2ban
if systemctl is-active --quiet fail2ban; then
    echo "✅ Fail2ban: Ready"
    log_action "✅ Fail2ban: Ready"
else
    echo "❌ Fail2ban: Not ready"
    log_action "❌ Fail2ban: Not ready"
    READY_FOR_PHASE2=false
fi

# 2. Check if security tools are installed
echo ""
echo "2. Checking security tools installation..."
log_action "2. Checking security tools installation..."

# Check Cloudflared
if command -v cloudflared &> /dev/null; then
    echo "✅ Cloudflared: Installed"
    log_action "✅ Cloudflared: Installed"
else
    echo "❌ Cloudflared: Not installed"
    log_action "❌ Cloudflared: Not installed"
    READY_FOR_PHASE2=false
fi

# Check Suricata
if command -v suricata &> /dev/null; then
    echo "✅ Suricata: Installed"
    log_action "✅ Suricata: Installed"
else
    echo "❌ Suricata: Not installed"
    log_action "❌ Suricata: Not installed"
    READY_FOR_PHASE2=false
fi

# Check Zeek
if command -v zeek &> /dev/null || command -v bro &> /dev/null; then
    echo "✅ Zeek/Bro: Installed"
    log_action "✅ Zeek/Bro: Installed"
else
    echo "❌ Zeek/Bro: Not installed"
    log_action "❌ Zeek/Bro: Not installed"
    READY_FOR_PHASE2=false
fi

# Check OSSEC
if command -v ossec-control &> /dev/null; then
    echo "✅ OSSEC: Installed"
    log_action "✅ OSSEC: Installed"
else
    echo "❌ OSSEC: Not installed"
    log_action "❌ OSSEC: Not installed"
    READY_FOR_PHASE2=false
fi

# 3. Check if Nextcloud is ready
echo ""
echo "3. Checking Nextcloud readiness..."
log_action "3. Checking Nextcloud readiness..."

if [ -d "/var/www/nextcloud" ]; then
    echo "✅ Nextcloud: Deployed"
    log_action "✅ Nextcloud: Deployed"
elif [ -d "/tmp/nextcloud" ]; then
    echo "⚠️  Nextcloud: Files available but not deployed"
    log_action "⚠️  Nextcloud: Files available but not deployed"
    READY_FOR_PHASE2=false
else
    echo "❌ Nextcloud: Not installed"
    log_action "❌ Nextcloud: Not installed"
    READY_FOR_PHASE2=false
fi

# 4. Check documentation and scripts
echo ""
echo "4. Checking documentation and scripts..."
log_action "4. Checking documentation and scripts..."

# Check if key documentation files exist
KEY_DOCS=(
    "$DOCS_DIR/final_next_steps_summary.md"
    "$DOCS_DIR/security_setup_roadmap.md"
    "$DOCS_DIR/manual_cloudflare_tunnel_cloudcurio.md"
)

ALL_DOCS_EXIST=true
for doc in "${KEY_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "✅ Documentation: $doc exists"
        log_action "✅ Documentation: $doc exists"
    else
        echo "❌ Documentation: $doc missing"
        log_action "❌ Documentation: $doc missing"
        ALL_DOCS_EXIST=false
        READY_FOR_PHASE2=false
    fi
done

# Check if key scripts exist
KEY_SCRIPTS=(
    "/home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
    "/home/cbwinslow/security_setup/setup_cloudflare_tunnel.sh"
    "/home/cbwinslow/security_setup/verify_core_components.sh"
)

ALL_SCRIPTS_EXIST=true
for script in "${KEY_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ Script: $script exists"
        log_action "✅ Script: $script exists"
    else
        echo "❌ Script: $script missing"
        log_action "❌ Script: $script missing"
        ALL_SCRIPTS_EXIST=false
        READY_FOR_PHASE2=false
    fi
done

# Summary
{
    echo ""
    echo "## Readiness Summary"
    echo ""
} >> $DOCS_DIR/phase2_readiness_check.md

echo ""
echo "=== Readiness Summary ==="
echo ""

if $READY_FOR_PHASE2; then
    echo "🎉 READY FOR PHASE 2!"
    log_action "🎉 READY FOR PHASE 2!"
    echo ""
    echo "All core components are ready for Phase 2 of your security setup."
    log_action "All core components are ready for Phase 2 of your security setup."
else
    echo "⚠️  NOT YET READY FOR PHASE 2"
    log_action "⚠️  NOT YET READY FOR PHASE 2"
    echo ""
    echo "Some components need to be completed before moving to Phase 2:"
    log_action "Some components need to be completed before moving to Phase 2:"
    
    # Specific next steps
    if [ ! -d "/var/www/nextcloud" ] && [ -d "/tmp/nextcloud" ]; then
        echo "1. Deploy Nextcloud using:"
        echo "   /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
        log_action "1. Deploy Nextcloud using /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
    fi
    
    if ! systemctl is-active --quiet apache2; then
        echo "2. Start Apache service:"
        echo "   sudo systemctl start apache2"
        log_action "2. Start Apache service: sudo systemctl start apache2"
    fi
    
    if ! systemctl is-active --quiet postgresql; then
        echo "3. Start PostgreSQL service:"
        echo "   sudo systemctl start postgresql"
        log_action "3. Start PostgreSQL service: sudo systemctl start postgresql"
    fi
    
    if [ ! -d "/var/www/nextcloud" ] && [ ! -d "/tmp/nextcloud" ]; then
        echo "4. Install Nextcloud files to /tmp/nextcloud"
        log_action "4. Install Nextcloud files to /tmp/nextcloud"
    fi
    
    if ! $ALL_DOCS_EXIST; then
        echo "5. Ensure all documentation files exist"
        log_action "5. Ensure all documentation files exist"
    fi
    
    if ! $ALL_SCRIPTS_EXIST; then
        echo "6. Ensure all scripts exist"
        log_action "6. Ensure all scripts exist"
    fi
fi

{
    echo ""
    echo "## Next Steps"
    echo ""
    echo "### If Ready for Phase 2:"
    echo "1. Configure monitoring tools (Suricata, Zeek, OSSEC)"
    echo "2. Set up log aggregation and analysis"
    echo "3. Configure firewall rules for all services"
    echo "4. Implement regular security updates"
    echo ""
    echo "### If Not Ready for Phase 2:"
    echo "1. Complete the tasks listed above"
    echo "2. Run this script again to check readiness"
    echo "3. Proceed to Phase 2 once all requirements are met"
    echo ""
    echo "### Resources:"
    echo "- Documentation: /home/cbwinslow/security_setup/docs/"
    echo "- Scripts: /home/cbwinslow/security_setup/"
    echo "- Troubleshooting: /home/cbwinslow/security_setup/troubleshoot.sh"
} >> $DOCS_DIR/phase2_readiness_check.md

log_action "Readiness check complete!"
echo ""
echo "=== Readiness Check Complete ==="
echo "Documentation created in $DOCS_DIR/phase2_readiness_check.md"
echo ""
echo "Next steps:"
if $READY_FOR_PHASE2; then
    echo "1. Proceed to Phase 2 of your security setup"
    echo "2. Configure monitoring tools (Suricata, Zeek, OSSEC)"
    echo "3. Set up log aggregation and analysis"
    echo "4. Configure firewall rules for all services"
    echo "5. Implement regular security updates"
else
    echo "1. Complete the tasks listed above"
    echo "2. Run this script again to check readiness"
    echo "3. Proceed to Phase 2 once all requirements are met"
fi
echo ""
echo "Resources:"
echo "- Documentation: /home/cbwinslow/security_setup/docs/"
echo "- Scripts: /home/cbwinslow/security_setup/"
echo "- Troubleshooting: /home/cbwinslow/security_setup/troubleshoot.sh"