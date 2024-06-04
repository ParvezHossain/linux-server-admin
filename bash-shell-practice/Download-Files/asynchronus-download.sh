#!/bin/bash

# Define the list of URLs to download
urls=(
    "https://github.com/ParvezHossain/linux-server-admin/raw/main/NFS/README.md"
    "https://github.com/ParvezHossain/linux-server-admin/raw/main/nginx/nginx.conf"
)

# Function to download a file asynchronously
download_file() {
    url=$1
    filename=$(basename "$url")
    curl -s "$url" -o "$filename" &
}

# Loop through each URL and initiate asynchronous download
for url in "${urls[@]}"; do
    download_file "$url"
    echo "Downloading $url..."
done

# Wait for all background processes to finish
wait

echo "All files downloaded successfully!"