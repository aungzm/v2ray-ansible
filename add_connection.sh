#!/bin/bash

# Variables
CONFIG_FILE="config.json" # Path to your main V2Ray server config file
VMESS_FOLDER="."          # Folder where vmess_{port_number}.json files are saved
DOMAIN="vpn.farmernet.org" # Your domain name
TLS="tls"                 # TLS security setting

# Check if the config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: $CONFIG_FILE does not exist."
  exit 1
fi

# Validate the number of connections to add
if [[ -z "$1" ]] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Usage: ./add_connection.sh <number_of_connections>"
  exit 1
fi

# Number of connections to add
NUM_CONNECTIONS=$1

# Get the last used port from the config.json file
LAST_PORT=$(jq '.inbounds | last | .port' "$CONFIG_FILE")
if [[ -z "$LAST_PORT" ]]; then
  echo "Error: Could not determine the last port."
  exit 1
fi

# Loop to add the specified number of connections
for ((i = 1; i <= NUM_CONNECTIONS; i++)); do
  # Calculate the next port
  NEW_PORT=$((LAST_PORT + i))

  # Generate a new UUID
  NEW_UUID=$(uuidgen)

  # Add the new connection to the config.json file
  jq --argjson port "$NEW_PORT" \
     --arg uuid "$NEW_UUID" \
     --arg path "/proxy/$NEW_PORT" \
     '.inbounds += [{
         port: $port,
         protocol: "vmess",
         settings: { clients: [{ id: $uuid, alterId: 0 }] },
         streamSettings: {
           network: "ws",
           wsSettings: { path: $path }
         }
       }]' "$CONFIG_FILE" > tmp_config.json && mv tmp_config.json "$CONFIG_FILE"

  echo "Added new connection with port $NEW_PORT and UUID $NEW_UUID to $CONFIG_FILE"

  # Create the corresponding vmess_{port_number}.json file
  VMESS_JSON_FILE="${VMESS_FOLDER}/vmess_${NEW_PORT}.json"
  cat <<EOF > "$VMESS_JSON_FILE"
{
  "v": "2",
  "ps": "NAG V2Ray Server",
  "add": "$DOMAIN",
  "port": "443",
  "id": "$NEW_UUID",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "$DOMAIN",
  "path": "/proxy/$NEW_PORT",
  "tls": "$TLS"
}
EOF

  echo "Generated client configuration: $VMESS_JSON_FILE"
done

# Restart V2Ray to apply changes
echo "Restarting V2Ray service..."
sudo systemctl restart v2ray
if [[ $? -eq 0 ]]; then
  echo "V2Ray service restarted successfully."
else
  echo "Failed to restart V2Ray service. Please check the service status."
  exit 1
fi

echo "Successfully added $NUM_CONNECTIONS connections and restarted V2Ray."
