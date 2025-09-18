#!/bin/bash
echo "Fixing Docker issues..."
sudo usermod -aG docker $USER
echo "User added to docker group. Please log out and back in."
