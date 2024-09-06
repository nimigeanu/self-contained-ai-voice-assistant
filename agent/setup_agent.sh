#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <ACCESS_KEY> <ACCESS_KEY_ID>"
  exit 1
fi

ACCESS_KEY=$1
ACCESS_KEY_ID=$2

# Update and install required packages
apt-get update && apt-get install -y python3.10-venv

# Create the working directory
mkdir -p /opt/agent

# Create a virtual environment
python3 -m venv /opt/agent/venv

# Activate the virtual environment
source /opt/agent/venv/bin/activate

# Install required Python packages
pip install livekit
pip install git+https://github.com/nimigeanu/livekit-agents.git#subdirectory=livekit-agents
pip install git+https://github.com/nimigeanu/livekit-agents.git#subdirectory=livekit-plugins/livekit-plugins-openai
pip install livekit-plugins-silero

# Download the main.py file
until wget -O /opt/agent/main.py https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/agent/main.py; do
    echo "Download failed. Retrying in 5 seconds..."
    sleep 5
done

echo "main.py has been downloaded."

# Set up the systemd service
SERVICE_FILE="/etc/systemd/system/agent.service"

cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=Agent Service
After=network.target

[Service]
ExecStart=/opt/agent/venv/bin/python /opt/agent/main.py start
WorkingDirectory=/opt/agent
StandardOutput=append:/opt/agent/agent.log
StandardError=append:/opt/agent/agent.log
Restart=always
User=root
Environment="LIVEKIT_URL=ws://127.0.0.1:7880"
Environment="LIVEKIT_API_KEY=$ACCESS_KEY"
Environment="LIVEKIT_API_SECRET=$ACCESS_KEY_ID"
Environment="OPENAI_API_KEY=dummy"

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable agent.service

# Start the service immediately
sudo systemctl start agent.service