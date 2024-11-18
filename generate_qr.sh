#!/bin/bash

# Define the folder where QR codes will be saved
OUTPUT_DIR="qrcodes"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all vmess*.json files in the current directory
for file in vmess*.json; do
  if [[ -f "$file" ]]; then
    # Read the JSON content and encode it as Base64
    base64_encoded=$(cat "$file" | base64 -w 0)

    # Prepend the "vmess://" scheme
    vmess_url="vmess://${base64_encoded}"

    # Extract the filename (without extension) to name the QR code
    filename=$(basename "$file" .json)

    # Generate the QR code and save it in the qrcodes folder
    qrencode -o "$OUTPUT_DIR/${filename}.png" "$vmess_url"

    echo "Generated QR code for $file -> $OUTPUT_DIR/${filename}.png"
  else
    echo "No vmess*.json files found."
  fi
done
