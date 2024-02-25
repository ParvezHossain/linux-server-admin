    curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest   | grep browser_download_url   | grep linux-amd64 | cut -d '"' -f 4   | wget -qi -

    docker run -p 9113:9113 -d nginx/nginx-prometheus-exporter:1.1.0 --nginx.scrape-uri=http://192.168.1.59:80/stub_status