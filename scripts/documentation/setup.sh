#!/bin/bash
#
# Setup Script for Documentation Management System
# This script helps set up the documentation management system
#

set -e  # Exit on error

echo "=========================================="
echo "Documentation Management System Setup"
echo "=========================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Repository root: $REPO_ROOT"
echo "Scripts directory: $SCRIPT_DIR"
echo ""

# Check Python version
echo "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "Found: $PYTHON_VERSION"
echo ""

# Check if pip is installed
echo "Checking pip..."
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is not installed"
    exit 1
fi

PIP_VERSION=$(pip3 --version)
echo "Found: $PIP_VERSION"
echo ""

# Ask if user wants to install dependencies
echo "Would you like to install Python dependencies? (y/n)"
read -r INSTALL_DEPS

if [[ "$INSTALL_DEPS" == "y" || "$INSTALL_DEPS" == "Y" ]]; then
    echo ""
    echo "Installing dependencies..."
    pip3 install -r "$SCRIPT_DIR/requirements.txt"
    echo ""
    echo "Dependencies installed successfully!"
else
    echo ""
    echo "Skipping dependency installation."
    echo "Note: You can install them later with:"
    echo "  pip3 install -r $SCRIPT_DIR/requirements.txt"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Directory structure:"
echo "  - documentation/ai_context/    - AI agent context documents"
echo "  - documentation/examples/      - Working code examples"
echo "  - documentation/scraped/       - Scraped documentation"
echo "  - documentation/top_100/       - Top 100 results from context7"
echo ""
echo "Next steps:"
echo ""
echo "1. Review configuration files:"
echo "   vim $SCRIPT_DIR/documentation_config.yaml"
echo "   vim $SCRIPT_DIR/sources.yaml"
echo ""
echo "2. Download documentation:"
echo "   cd $SCRIPT_DIR"
echo "   python3 download_documentation.py"
echo ""
echo "3. Process and index:"
echo "   python3 ingest_knowledge.py"
echo "   python3 ingest_examples.py"
echo "   python3 label_content.py"
echo ""
echo "4. Search and manage:"
echo "   python3 manage_knowledge_base.py search 'docker'"
echo "   python3 manage_knowledge_base.py stats"
echo ""
echo "For detailed documentation, see:"
echo "  - $REPO_ROOT/documentation/README.md"
echo "  - $SCRIPT_DIR/README.md"
echo ""
