#!/bin/bash

# This script downloads files from URLs listed in a text file.
# It utilizes parallel processing to optimize the use of CPU resources
# and handles errors gracefully, logging success and error messages.

# Constants
URLS_FILE="urls.txt"                 # File containing the list of URLs to download
LOG_FILE="download.log"              # Log file for successful downloads
ERROR_LOG_FILE="download_errors.log" # Log file for errors

# Function to check if the URLs file exists
check_urls_file() {
    if [ ! -f "$URLS_FILE" ]; then
        # Log error if the file does not exist and exit
        echo "URLs file '$URLS_FILE' not found." | tee -a "$ERROR_LOG_FILE"
        exit 1
    fi
}

# Function to read URLs from the file into an array
read_urls() {
    readarray -t urls <"$URLS_FILE" # Read URLs into an array
    if [ ${#urls[@]} -eq 0 ]; then
        # Log error if no URLs are found and exit
        echo "No URLs found in the file." | tee -a "$ERROR_LOG_FILE"
        exit 1
    fi
}

# Function to download a file
download_file() {
    local url=$1                      # URL to download
    local filename=$(basename "$url") # Extract the filename from the URL

    # Download the file using curl with error handling
    if curl -s --fail "$url" -o "$filename"; then
        # Log success if the download is successful
        echo "Downloaded: $filename" | tee -a "$LOG_FILE"
    else
        # Log error if the download fails
        echo "Failed to download: $url" | tee -a "$ERROR_LOG_FILE"
    fi
}

# Function to download files in parallel using GNU Parallel
download_files_parallel() {
    export -f download_file                             # Export the function for parallel processing
    parallel -j $(nproc) download_file ::: "${urls[@]}" # Use all CPU cores for parallel processing
}

# Main function to orchestrate the download process
main() {
    check_urls_file         # Check if the URLs file exists
    read_urls               # Read URLs from the file
    download_files_parallel # Download files in parallel
    # Log a final message indicating completion
    echo "All files processed. Check '$LOG_FILE' for details and '$ERROR_LOG_FILE' for any errors."
}

# Execute the main function
main
