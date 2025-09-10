#!/bin/bash

# Install Nginx
sudo -s <<< 'apt update && apt install -y nginx'
sudo systemctl enable --now nginx
