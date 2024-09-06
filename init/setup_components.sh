#!/bin/bash

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <domain> <record> <ACCESS_KEY> <ACCESS_KEY_ID>"
  exit 1
fi

echo "Setting up LocalAI"
wget https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/localai/setup_localai.sh
chmod +x setup_localai.sh
./setup_localai.sh

echo "Warming up local-ai" 

echo "Trying audio/transcriptions ..." 
wget --quiet -O gb1.ogg https://upload.wikimedia.org/wikipedia/commons/5/52/En-us-hello.ogg
while ! curl -m 120 -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/audio/transcriptions  -H "Content-Type:multipart/form-data"  -F file="@$PWD/gb1.ogg" -F model="whisper-1" | grep -q 200; do
  echo "Retrying audio/transcriptions ..." 
  sleep 10
done

echo "Trying audio/speech ..."
while ! curl -m 120 -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/audio/speech -H "Content-Type: application/json" -d '{"model":"tts-1", "input": "Hi, this is a test." }' --output audio.wav | grep -q 200; do
  echo "Retrying audio/speech ..."
  sleep 10
done

echo "Trying chat/completions ..."
while ! curl -m 120 -s -o /dev/null -w "%{http_code}" http://127.0.01:8080/v1/chat/completions -H "Content-Type: application/json" -d '{"messages": [{"role": "user", "content": "Say this is a test!"}],"temperature": 0.7}' | grep -q 200; do
  echo "Retrying chat/completions ..."
  sleep 10
done

echo "Setting up LiveKit"
wget https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/livekit/setup_livekit.sh
chmod +x setup_livekit.sh
./setup_livekit.sh $1 $2 $3 $4
echo "Done setting up LiveKit"

echo "Setting up LiveKit Agent"
wget https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/agent/setup_agent.sh
chmod +x setup_agent.sh
./setup_agent.sh $3 $4
echo "Done setting up LiveKit Agent"

echo "Setting up front end"
wget https://lostshadow.s3.amazonaws.com/self-contained-ai-voice-assistant/frontend/setup_frontend.sh
chmod +x setup_frontend.sh
./setup_frontend.sh $1 $2 $3 $4
echo "Done setting up front end"
echo "Setup complete. You may now connect to https://$2.$1"