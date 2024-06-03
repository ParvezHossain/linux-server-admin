Here is a full script example that you can use to automate the process of updating and blocking Russian IP addresses
     
    sudo chmod +x /etc/nginx/block-russian-ip.sh
    0 0 * * * /etc/nginx/update_russian_ips.sh


Edit Nginx file **/etc/nginx/nginx.conf**

    http {
    include /etc/nginx/blocked_ips.conf;

    server {
        # Your existing server configuration
        }
    }

Don't forget to restart the nginx 

    sudo systemctl restart nginx
