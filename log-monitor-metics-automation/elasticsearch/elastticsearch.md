It has a dependency on Java.

* lsb_release -a
* sudo curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
* echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
*  Update package lists by using the following command
* sudo apt update
* sudo apt install elasticsearch
* sudo systemctl daemon-reload
* sudo systemctl enable elasticsearch
* sudo systemctl status elasticsearch
* sudo systemctl start elasticsearch
* nano /etc/elasticsearch/elasticsearch.yml
#uncomment these lines
network.host: 192.168.1.59 [this is your ip/network]
http.port: 9200 <The PORT you want to run>
discovery.seed_hosts: 192.168.1.59

#After changing this configuration, restart elasticsearch service

Access Elasticsearch using host:port [192.168.1.59:9200]