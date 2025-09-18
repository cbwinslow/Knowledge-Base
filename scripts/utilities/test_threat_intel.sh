#!/bin/bash

echo "=== Testing Threat Intelligence Tools ==="
echo ""

echo "1. Testing Python packages..."
python3 -c "import vt, greynoise; print('VirusTotal and GreyNoise libraries installed')" 2>/dev/null || echo "Some Python packages missing"

echo ""
echo "2. Testing Snyk..."
which snyk &>/dev/null && echo "Snyk installed" || echo "Snyk not installed"

echo ""
echo "3. Testing security testing tools..."
which nikto sqlmap lynis clamscan &>/dev/null && echo "Security testing tools installed" || echo "Some security testing tools missing"

echo ""
echo "4. Testing digital forensics tools..."
which yara volatility foremost &>/dev/null && echo "Digital forensics tools installed" || echo "Some digital forensics tools missing"

echo ""
echo "=== Test Complete ==="
