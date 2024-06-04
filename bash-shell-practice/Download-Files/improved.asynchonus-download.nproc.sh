#!/bin/bash

# Check if the file containing URLs exists
urls_file="urls.txt"
if [ ! -f "$urls_file" ]; then
    echo "URLs file '$urls_file' not found."
    exit 1
fi

# Read URLs from the file into an array
readarray -t urls < "$urls_file"

# Function to download a file
download_file() {
    url=$1
    filename=$(basename "$url")
    curl -s "$url" -o "$filename"
}

# Download files in parallel using GNU Parallel with higher job limit
parallel -j $(nproc) download_file ::: "${urls[@]}"

echo "All files downloaded successfully!"
