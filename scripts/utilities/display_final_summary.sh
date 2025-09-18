#!/bin/bash

# Display Final Summary Script
# This script displays the final summary and next steps

echo "=== Security Setup - Final Summary and Next Steps ==="
echo ""

# Display the final summary
cat /home/cbwinslow/security_setup/docs/final_next_steps_summary.md

echo ""
echo "=== Quick Reference ==="
echo ""

echo "Immediate Next Steps:"
echo "===================="
echo "1. Deploy Nextcloud:"
echo "   /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo ""
echo "2. Start required services:"
echo "   sudo systemctl start postgresql"
echo "   sudo systemctl start apache2"
echo ""
echo "3. Configure Cloudflare Tunnel:"
echo "   Follow: /home/cbwinslow/security_setup/docs/manual_cloudflare_tunnel_cloudcurio.md"
echo ""
echo "Medium Priority Next Steps:"
echo "=========================="
echo "4. Configure monitoring tools (Suricata, Zeek, OSSEC)"
echo "5. Install threat intelligence tools (MISP, TheHive/Cortex)"
echo ""
echo "Long-term Next Steps:"
echo "===================="
echo "6. Install penetration testing tools (Metasploit, Nikto, SQLMap, etc.)"
echo ""
echo "Documentation:"
echo "============="
echo "Final summary: /home/cbwinslow/security_setup/docs/final_next_steps_summary.md"
echo "Roadmap: /home/cbwinslow/security_setup/docs/security_setup_roadmap.md"
echo "Verification: /home/cbwinslow/security_setup/docs/core_components_verification.md"
echo ""
echo "Scripts:"
echo "======="
echo "Deploy Nextcloud: /home/cbwinslow/security_setup/deploy_nextcloud_simple.sh"
echo "Verify setup: /home/cbwinslow/security_setup/verify_core_components.sh"
echo "Troubleshoot: /home/cbwinslow/security_setup/troubleshoot.sh"
echo ""