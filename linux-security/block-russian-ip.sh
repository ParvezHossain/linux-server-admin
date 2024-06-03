#!/bin/bash

# Step 1: Download the list of IP ranges allocated to Russia
wget -O /etc/nginx/russian_ips.txt https://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone

# Step 2: Convert the list into Nginx format
cat /etc/nginx/russian_ips.txt | sed -e 's/^/deny /' -e 's/$/;/' > /etc/nginx/blocked_ips.conf

# Step 3: Reload Nginx to apply the new rules
sudo systemctl reload nginx
