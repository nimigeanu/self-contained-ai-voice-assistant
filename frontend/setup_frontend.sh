#!/bin/bash

# Check if the number of arguments passed is exactly 4
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <domain> <record> <ACCESS_KEY> <ACCESS_KEY_ID>"
  exit 1
fi

# Export the domain name and stack name from the passed arguments
export DOMAIN_NAME=$1
export STACK_NAME=$2

# Navigate to the /opt directory
cd /opt

# Clone the LiveKit examples repository
git clone https://github.com/livekit/agents-playground frontend

# Navigate to the cloned repository directory
cd frontend

# Copy the example environment file to a local environment file
cp .env.example .env.local

# Set LIVEKIT_API_KEY in .env.local
sed -i 's|LIVEKIT_API_KEY=.*|LIVEKIT_API_KEY='"$3"'|' .env.local

# Set LIVEKIT_API_SECRET in .env.local
sed -i 's|LIVEKIT_API_SECRET=.*|LIVEKIT_API_SECRET='"$4"'|' .env.local

# Set LIVEKIT_URL in .env.local
sed -i 's|NEXT_PUBLIC_LIVEKIT_URL=.*|NEXT_PUBLIC_LIVEKIT_URL=wss://'"$2.$1"':8443|' .env.local

sed -i 's|video:.*|video: false|' .env.local
sed -i 's|camera:.*|camera: false|' .env.local
sed -i '/title:/c\title: '\''Open-source self contained AI voice assistant'\''' .env.local
sed -i '/description:/c\description: '\''Derivative of KITT by LiveKit; made with open-source components; does not rely on external services'\''' .env.local
sed -i '/github_link:/c\github_link: '\''https://github.com/nimigeanu/self-contained-ai-voice-assistant'\''' .env.local

# Download and execute the Node.js setup script for Node.js version 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

# Install Node.js
apt-get install -y nodejs

# Install pnpm globally
npm install -g pnpm

# Install project dependencies using pnpm
pnpm install

# Download a server.js file from an S3 bucket
wget https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/frontend/server.js

# Replace 'next start' with 'node server.js' in the package.json file
sed -i 's/next start/node server.js/' package.json

# Build the project using pnpm
pnpm build

SERVICE_NAME="larynx-frontend"
WORKING_DIR="/opt/frontend"
LOG_FILE="$WORKING_DIR/app.log"
USER="root"  # Replace with your actual username
Environment="DOMAIN_NAME=$1"
Environment="STACK_NAME=$2"
PNPM_PATH=$(which pnpm)  # Finds the path to pnpm

# Create the service file content
SERVICE_FILE_CONTENT="[Unit]
Description=Larynx Frontend Service
After=network.target

[Service]
ExecStart=$PNPM_PATH start
WorkingDirectory=$WORKING_DIR
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
Environment="DOMAIN_NAME=$1"
Environment="STACK_NAME=$2"
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target"

# Create the systemd service file
echo "Creating systemd service file..."
echo "$SERVICE_FILE_CONTENT" | sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling service to start on boot..."
sudo systemctl enable $SERVICE_NAME.service

# Start the service immediately
echo "Starting service..."
sudo systemctl start $SERVICE_NAME.service

# Check the status of the service
# echo "Checking service status..."
# sudo systemctl status $SERVICE_NAME.service

echo "Setup complete. The service is now running and will start automatically on boot."
