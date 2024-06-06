#!/bin/bash

# Function to handle cleanup on exit
cleanup() {
    echo "Cleaning up..."
    exit 0
}

# Set trap to catch exit signals
trap cleanup SIGINT SIGTERM

while true; do
    clear

    echo "System Resource Usage Summary"
    echo "============================="

    # CPU Usage
    echo "CPU Usage:"
    mpstat 1 1 | awk '/Average/ && $12 ~ /[0-9.]+/ { print 100 - $12"%"}'
    echo

    # Per CPU Usage
    echo "Per CPU Usage:"
    mpstat -P ALL 1 1 | grep -E "CPU|Average" | awk '{if (NR!=1) print $3 " : " 100-$13 "%"}'
    echo

    # RAM Usage
    echo "Memory Usage:"
    free -h | awk '/Mem/ {print "Total: " $2 "\nUsed: " $3 "\nFree: " $4 "\nShared: " $5 "\nBuffers/Cache: " $6 "\nAvailable: " $7}'
    echo

    # Swap Usage
    echo "Swap Usage:"
    free -h | awk '/Swap/ {print "Total: " $2 "\nUsed: " $3 "\nFree: " $4}'
    echo

    # Disk I/O
    echo "Disk I/O Usage:"
    iostat -dx 1 1 | awk 'NR>6 {print $1 ": " $14 " KB_read/s, " $15 " KB_wrtn/s"}'
    echo

    # Network Bandwidth
    echo "Network Bandwidth Usage:"
    ifstat -i eth0 1 1 | awk 'NR==3 {print "In: " $1 " KB/s\nOut: " $2 " KB/s"}'
    echo

    # Top Processes by CPU Usage
    echo "Top Processes by CPU Usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 10
    echo

    # Top Processes by Memory Usage
    echo "Top Processes by Memory Usage:"
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 10
    echo

    # Running Threads
    echo "Threads Count:"
    ps -eo nlwp | tail -n +2 | awk '{ num_threads += $1 } END { print num_threads }'
    echo

    # Open Ports
    echo "Open Ports:"
    ss -tuln | grep LISTEN
    echo

    # System Uptime
    echo "System Uptime:"
    uptime -p
    echo

    # Load Average
    echo "Load Average:"
    uptime | awk -F'load average:' '{ print $2 }'
    echo

    # Temperature (if sensors command is available)
    if command -v sensors &>/dev/null; then
        echo "Temperature:"
        sensors | awk '/^Core/ {print $1 ": " $3}'
        echo
    fi

    echo "Press Ctrl+C to exit..."

    # Wait for 30 seconds before refreshing
    sleep 30
done
