#!/bin/bash
# System Setup Tools Launcher

echo "System Setup Tools Launcher"
echo "=========================="
echo ""

PS3="Select an option: "

options=(
  "Launch Git Repository Manager TUI"
  "View PostgreSQL Installation Guide"
  "View Proxy Configuration Guide"
  "View System Setup Summary"
  "View Ansible Setup Guide"
  "View PostgreSQL Backup Fix Guide"
  "View Enhanced Server Setup Guide"
  "View Enhanced Server Setup Quick Install Guide"
  "View AI Monitoring System Architecture"
  "View AI Monitoring System Documentation"
  "Run AI Monitoring System Demo"
  "View CloudCurio AI Stack Implementation Summary"
  "Run PostgreSQL Installation (requires sudo)"
  "Quit"
)

select opt in "${options[@]}"
do
  case $opt in
    "Launch Git Repository Manager TUI")
      echo "Launching Git Repository Manager..."
      if [ -f "/home/cbwinslow/git_repo_manager/src/main.py" ]; then
        python3 /home/cbwinslow/git_repo_manager/src/main.py
      else
        echo "Git Repository Manager not found!"
      fi
      ;;
    "View PostgreSQL Installation Guide")
      echo "Displaying PostgreSQL Installation Guide..."
      if [ -f "/home/cbwinslow/POSTGRESQL_INSTALLATION.md" ]; then
        less /home/cbwinslow/POSTGRESQL_INSTALLATION.md
      else
        echo "PostgreSQL Installation Guide not found!"
      fi
      ;;
    "View Proxy Configuration Guide")
      echo "Displaying Proxy Configuration Guide..."
      if [ -f "/home/cbwinslow/PROXY_CONFIGURATION.sh" ]; then
        less /home/cbwinslow/PROXY_CONFIGURATION.sh
      else
        echo "Proxy Configuration Guide not found!"
      fi
      ;;
    "View System Setup Summary")
      echo "Displaying System Setup Summary..."
      if [ -f "/home/cbwinslow/SYSTEM_SETUP_SUMMARY.md" ]; then
        less /home/cbwinslow/SYSTEM_SETUP_SUMMARY.md
      else
        echo "System Setup Summary not found!"
      fi
      ;;
    "View Ansible Setup Guide")
      echo "Displaying Ansible Setup Guide..."
      if [ -f "/home/cbwinslow/ANSIBLE_SETUP.md" ]; then
        less /home/cbwinslow/ANSIBLE_SETUP.md
      else
        echo "Ansible Setup Guide not found!"
      fi
      ;;
    "View PostgreSQL Backup Fix Guide")
      echo "Displaying PostgreSQL Backup Fix Guide..."
      if [ -f "/home/cbwinslow/FIX_POSTGRESQL_BACKUP.md" ]; then
        less /home/cbwinslow/FIX_POSTGRESQL_BACKUP.md
      else
        echo "PostgreSQL Backup Fix Guide not found!"
      fi
      ;;
    "View Enhanced Server Setup Guide")
      echo "Displaying Enhanced Server Setup Guide..."
      if [ -f "/home/cbwinslow/ENHANCED_SERVER_SETUP_README.md" ]; then
        less /home/cbwinslow/ENHANCED_SERVER_SETUP_README.md
      else
        echo "Enhanced Server Setup Guide not found!"
      fi
      ;;
    "View Enhanced Server Setup Quick Install Guide")
      echo "Displaying Enhanced Server Setup Quick Install Guide..."
      if [ -f "/home/cbwinslow/install_enhanced_setup.sh" ]; then
        less /home/cbwinslow/install_enhanced_setup.sh
      else
        echo "Enhanced Server Setup Quick Install Guide not found!"
      fi
      ;;
    "View AI Monitoring System Architecture")
      echo "Displaying AI Monitoring System Architecture..."
      if [ -f "/home/cbwinslow/AI_MONITORING_ARCHITECTURE.md" ]; then
        less /home/cbwinslow/AI_MONITORING_ARCHITECTURE.md
      else
        echo "AI Monitoring System Architecture not found!"
      fi
      ;;
    "View AI Monitoring System Documentation")
      echo "Displaying AI Monitoring System Documentation..."
      if [ -f "/home/cbwinslow/AI_MONITORING_DOCUMENTATION.md" ]; then
        less /home/cbwinslow/AI_MONITORING_DOCUMENTATION.md
      else
        echo "AI Monitoring System Documentation not found!"
      fi
      ;;
    "Run AI Monitoring System Demo")
      echo "Running AI Monitoring System Demo..."
      if [ -f "/home/cbwinslow/ai_monitoring_demo.sh" ]; then
        /home/cbwinslow/ai_monitoring_demo.sh
      else
        echo "AI Monitoring System Demo not found!"
      fi
      ;;
    "View CloudCurio AI Stack Implementation Summary")
      echo "Displaying CloudCurio AI Stack Implementation Summary..."
      if [ -f "/home/cbwinslow/cloudcurio/IMPLEMENTATION_SUMMARY.md" ]; then
        less /home/cbwinslow/cloudcurio/IMPLEMENTATION_SUMMARY.md
      else
        echo "CloudCurio AI Stack Implementation Summary not found!"
      fi
      ;;
    "Run PostgreSQL Installation (requires sudo)")
      echo "Running PostgreSQL Installation..."
      if [ -f "/tmp/install_postgres.sh" ]; then
        echo "This will install PostgreSQL with sudo privileges."
        echo "Please enter your password when prompted."
        sudo /tmp/install_postgres.sh
      else
        echo "Installation script not found!"
        echo "Please run the create_postgres_install_script.sh first."
      fi
      ;;
    "Quit")
      echo "Goodbye!"
      break
      ;;
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
  echo ""
done