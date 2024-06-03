# For every minutes. (Unrealistic example)
* *     * * *   sct     /var/www/html/backup-mysql.sh >> /var/www/html/backup.log 2>&1 
# For everyday min-night
0 0 * * * sct /var/www/html/backup-mysql.sh >> /var/www/html/backup.log 2>&1

sudo chmod +x /var/www/html/backup-mysql.sh
sudo touch /var/www/html/backup.log
sudo chown sct:sct /var/www/html/backup.log
sudo chmod 644 /var/www/html/backup.log
sudo chown -R sct:sct /var/www/html
ls -l /var/www/html/backup-mysql.sh
ls -l /var/www/html/backup.log
