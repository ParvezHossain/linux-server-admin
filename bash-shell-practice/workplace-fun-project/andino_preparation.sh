#!/bin/bash

function manage_pm2_process() {
    PM2_PROCESS_NAME="device_srv"

    # Check if the process is running
    if pm2 describe $PM2_PROCESS_NAME &>/dev/null; then
        pm2 delete $PM2_PROCESS_NAME
    fi

    # Start the PM2 process
    npm run start
    pm2 save --force
    pm2 startup
}

cd /home/pi/andino && $(typeset -f manage_pm2_process);