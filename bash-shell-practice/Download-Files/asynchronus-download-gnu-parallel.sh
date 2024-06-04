#  GNU Parallel (parallel)

#!/bin/bash

# Define the list of URLs to download
urls=(
    "https://github.com/ParvezHossain/linux-server-admin/raw/main/NFS/README.md"
    "https://github.com/ParvezHossain/linux-server-admin/raw/main/nginx/nginx.conf"
)

# Function to download a file
download_file() {
    url=$1
    filename=$(basename "$url")
    curl -s "$url" -o "$filename"
}

# Download files in parallel using GNU Parallel
parallel -j 0 download_file ::: "${urls[@]}"

echo "All files downloaded successfully!"
