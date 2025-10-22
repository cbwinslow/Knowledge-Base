#!/usr/bin/env python3
"""
Basic test script to verify the documentation management system setup
Tests basic functionality without requiring all dependencies
"""

import json
import os
import sys
from pathlib import Path

def test_directory_structure():
    """Test that all required directories exist"""
    print("Testing directory structure...")
    
    base_dir = Path(__file__).parent.parent.parent / 'documentation'
    required_dirs = [
        base_dir,
        base_dir / 'ai_context',
        base_dir / 'examples',
        base_dir / 'scraped',
        base_dir / 'top_100'
    ]
    
    all_exist = True
    for dir_path in required_dirs:
        if dir_path.exists():
            print(f"  ✓ {dir_path.name}")
        else:
            print(f"  ✗ {dir_path.name} - MISSING")
            all_exist = False
    
    return all_exist

def test_script_files():
    """Test that all required scripts exist"""
    print("\nTesting script files...")
    
    script_dir = Path(__file__).parent
    required_scripts = [
        'download_documentation.py',
        'ingest_knowledge.py',
        'ingest_examples.py',
        'label_content.py',
        'manage_knowledge_base.py'
    ]
    
    all_exist = True
    for script in required_scripts:
        script_path = script_dir / script
        if script_path.exists():
            print(f"  ✓ {script}")
        else:
            print(f"  ✗ {script} - MISSING")
            all_exist = False
    
    return all_exist

def test_config_files():
    """Test that configuration files exist"""
    print("\nTesting configuration files...")
    
    script_dir = Path(__file__).parent
    required_configs = [
        'documentation_config.yaml',
        'sources.yaml',
        'requirements.txt'
    ]
    
    all_exist = True
    for config in required_configs:
        config_path = script_dir / config
        if config_path.exists():
            print(f"  ✓ {config}")
        else:
            print(f"  ✗ {config} - MISSING")
            all_exist = False
    
    return all_exist

def test_readme_files():
    """Test that README files exist"""
    print("\nTesting README files...")
    
    base_dir = Path(__file__).parent.parent.parent / 'documentation'
    required_readmes = [
        base_dir / 'README.md',
        base_dir / 'ai_context' / 'README.md',
        base_dir / 'examples' / 'README.md',
        base_dir / 'scraped' / 'README.md',
        base_dir / 'top_100' / 'README.md',
        Path(__file__).parent / 'README.md'
    ]
    
    all_exist = True
    for readme in required_readmes:
        if readme.exists():
            print(f"  ✓ {readme.parent.name}/{readme.name}")
        else:
            print(f"  ✗ {readme.parent.name}/{readme.name} - MISSING")
            all_exist = False
    
    return all_exist

def test_script_syntax():
    """Test that scripts have valid Python syntax"""
    print("\nTesting script syntax...")
    
    script_dir = Path(__file__).parent
    scripts = [
        'download_documentation.py',
        'ingest_knowledge.py',
        'ingest_examples.py',
        'label_content.py',
        'manage_knowledge_base.py'
    ]
    
    all_valid = True
    for script in scripts:
        script_path = script_dir / script
        try:
            with open(script_path, 'r') as f:
                compile(f.read(), script_path, 'exec')
            print(f"  ✓ {script}")
        except SyntaxError as e:
            print(f"  ✗ {script} - SYNTAX ERROR: {e}")
            all_valid = False
    
    return all_valid

def test_permissions():
    """Test that scripts have execute permissions"""
    print("\nTesting script permissions...")
    
    script_dir = Path(__file__).parent
    scripts = [
        'download_documentation.py',
        'ingest_knowledge.py',
        'ingest_examples.py',
        'label_content.py',
        'manage_knowledge_base.py'
    ]
    
    all_executable = True
    for script in scripts:
        script_path = script_dir / script
        if os.access(script_path, os.X_OK):
            print(f"  ✓ {script}")
        else:
            print(f"  ⚠ {script} - Not executable (run: chmod +x {script})")
            # Not marking as failure since it's not critical
    
    return True

def main():
    """Run all tests"""
    print("=" * 60)
    print("Documentation Management System - Basic Tests")
    print("=" * 60)
    print()
    
    results = []
    
    results.append(("Directory Structure", test_directory_structure()))
    results.append(("Script Files", test_script_files()))
    results.append(("Configuration Files", test_config_files()))
    results.append(("README Files", test_readme_files()))
    results.append(("Script Syntax", test_script_syntax()))
    results.append(("Script Permissions", test_permissions()))
    
    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    
    all_passed = True
    for test_name, passed in results:
        status = "PASSED" if passed else "FAILED"
        symbol = "✓" if passed else "✗"
        print(f"  {symbol} {test_name}: {status}")
        if not passed:
            all_passed = False
    
    print("=" * 60)
    
    if all_passed:
        print("\n✓ All tests passed! The system is ready to use.")
        print("\nNext steps:")
        print("  1. Install dependencies: pip3 install -r requirements.txt")
        print("  2. Review configuration: vim documentation_config.yaml")
        print("  3. Run download script: python3 download_documentation.py")
        return 0
    else:
        print("\n✗ Some tests failed. Please review the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
