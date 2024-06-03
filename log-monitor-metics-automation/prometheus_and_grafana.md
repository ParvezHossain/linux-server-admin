Visit the [Prometheus downloads](https://prometheus.io/download/) and make a note of the most recent release. The most recent LTS release is clearly indicated on the site.

    wget https://github.com/prometheus/prometheus/releases/download/v2.37.6/prometheus-2.37.6.linux-amd64.tar.gz

Extract the archived Prometheus files

    tar xvfz prometheus-*.tar.gz

(Optional) After the files have been extracted, delete the archive or move it to a different location for storage.

    rm prometheus-*.tar.gz

Create two new directories for Prometheus to use. The /etc/prometheus directory stores the Prometheus configuration files. The /var/lib/prometheus directory holds application data.

    sudo mkdir /etc/prometheus /var/lib/prometheus

Move into the main directory of the extracted prometheus folder. Substitute the name of the actual directory in place of prometheus-2.37.6.linux-amd64.

    cd prometheus-2.37.6.linux-amd64

Move the prometheus and promtool directories to the /usr/local/bin/ directory. This makes Prometheus accessible to all users.

    sudo mv prometheus promtool /usr/local/bin/

Move the prometheus.yml YAML configuration file to the /etc/prometheus directory.

    sudo mv prometheus.yml /etc/prometheus/prometheus.yml

The consoles and console_libraries directories contain the resources necessary to create customized consoles. This feature is more advanced and is not covered in this guide. However, these files should also be moved to the etc/prometheus directory in case they are ever required.

> **Note:**
> After these directories are moved over, only the LICENSE and NOTICE files remain in the original directory. Back up these documents to another location and delete the `prometheus-releasenum.linux-amd64` directory.

    sudo mv consoles/ console_libraries/ /etc/prometheus/

Verify that Prometheus is successfully installed using the below command:

    prometheus --version


**How to Configure Prometheus as a Service**

Although `Prometheus` can be started and stopped from the command line, it is more convenient to run it as a service using the systemctl utility. This allows it to run in the background.

Before Prometheus can monitor any external systems, additional configuration details must be added to the `prometheus.yml` file. However, Prometheus is already configured to monitor itself, allowing for a quick sanity test. To configure Prometheus, follow the steps below.

*Create a prometheus user. The following command creates a system user*

> **What does this command do?**
> sudo useradd -rs /bin/false prometheus is used to create a system user named "prometheus" on a Unix-like operating system. The -r option designates it as a system account, typically employed for background services, and the -s /bin/false option sets its shell to /bin/false. A shell of /bin/false ensures that the user cannot engage in interactive logins, which is a security measure for service accounts. The sudo prefix grants superuser privileges for executing this command. Overall, this user creation command is tailored for establishing a dedicated and secure system account, suitable for running specific services or processes such as Prometheus.

    sudo useradd -rs /bin/false prometheus

*Assign ownership of the two directories created in the previous section to the new prometheus user*

    sudo chown -R prometheus: /etc/prometheus /var/lib/prometheus

*To allow Prometheus to run as a service, create a prometheus.service file using the following command:*

    sudo nano /etc/systemd/system/prometheus.service

Enter the following content into the file:

    [Unit]
    Description=Prometheus
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=prometheus
    Group=prometheus
    Type=simple
    Restart=on-failure
    RestartSec=5s
    ExecStart=/usr/local/bin/prometheus \
        --config.file /etc/prometheus/prometheus.yml \
        --storage.tsdb.path /var/lib/prometheus/ \
        --web.console.templates=/etc/prometheus/consoles \
        --web.console.libraries=/etc/prometheus/console_libraries \
        --web.listen-address=0.0.0.0:9090 \
        --web.enable-lifecycle \
        --log.level=info

    [Install]
    WantedBy=multi-user.target

# Systemd Configuration for Prometheus

## Unit Section:

- **Description:** Prometheus: Describes the purpose of the unit, which is the Prometheus service.
- **Wants=network-online.target and After=network-online.target:** Specify that the Prometheus service requires the `network-online.target` to be reached before starting. This ensures network connectivity is available.

## Service Section:

- **User=prometheus and Group=prometheus:** Sets the user and group under which the Prometheus service will run. This enhances security by restricting the service's permissions.
- **Type=simple:** Defines the process execution type as simple, meaning systemd will consider the service started once the `ExecStart` command has been executed.
- **Restart=on-failure and RestartSec=5s:** Configures the service to restart in case of failure, with a 5-second delay between restart attempts.
- **ExecStart=/usr/local/bin/prometheus ...:** Specifies the command to start the Prometheus service along with its configuration options.

## Install Section:

- **WantedBy=multi-user.target:** Indicates that the Prometheus service should be started as part of the `multi-user.target`, which is a default target for user sessions.

In summary, this systemd configuration ensures that Prometheus runs with the specified user and group, has dependencies on network availability, and is configured to restart in case of failure. The `ExecStart` command defines the executable and its associated configuration options.

*Reload the systemctl daemon.*

    sudo systemctl daemon-reload

**_(Optional)_** Use `systemctl enable` to configure the Prometheus service to automatically start when the system boots. If this command is not added, Prometheus must be launched manually.

    sudo systemctl enable prometheus

*Start the prometheus service and review the status command to ensure it is active.*

> **Note:**
> If the `prometheus` service fails to start properly, run the command `journalctl -u prometheus -f --no-pager` and review the output for errors.

    sudo systemctl start prometheus
    sudo systemctl status prometheus

Access the Prometheus web interface and dashboard at http://local_ip_addr:9090. Replace local_ip_addr with the address of the monitoring server. Because Prometheus is using the default configuration file, it does not display much information yet.



###How to Install and Configure Node Exporter on the Client

Before a remote system can be monitored, it must have some type of client to collect the statistics. Several third-party clients are available. However, for ease of use, Prometheus recommends the Node Exporter client. After Node Exporter is installed on a client, the client can be added to the list of servers to scrape in prometheus.yml.

To install Node Exporter, follow these steps. Repeat these instructions for every client.

> **Note**
> When Node Exporter is running, its collection of statistics is available on port 9100. This port is accessible on the internet and anyone running Prometheus elsewhere can potentially collect them. If you are using a firewall, you must open port 9100 using the command sudo ufw allow 9100.

Consult the [Node Exporter section of the Prometheus downloads page](https://prometheus.io/download/#node_exporter) and determine the latest release.

Use wget to download this release. The format for the file is https://github.com/prometheus/node_exporter/releases/download/v[release_num]/node_exporter-[release_num].linux-amd64.tar.gz. Replace [release_num] with the number corresponding to the actual release. For example, the following example demonstrates how to download Node Exporter release 1.5.0.

    wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz

Extract the application.

    tar xvfz node_exporter-*.tar.gz

Move the executable to usr/local/bin so it is accessible throughout the system.

    sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin

(Optional) Remove any remaining files.

    rm -r node_exporter-1.5.0.linux-amd64*

There are two ways of running Node Exporter. It can be launched from the terminal using the command node_exporter. Or, it can be activated as a system service. Running it from the terminal is less convenient. But this might not be a problem if the tool is only intended for occasional use. To run Node Exporter manually, use the following command. The terminal outputs details regarding the statistics collection process.

    node_exporter

It is more convenient to run Node Exporter as a service. To run Node Exporter this way, first, create a node_exporter user.

    sudo useradd -rs /bin/false node_exporter


Create a service file for systemctl to use. The file must be named node_exporter.service and should have the following format. Most of the fields are similar to those found in prometheus.service, as described in the previous section.

    sudo nano /etc/systemd/system/node_exporter.service

Add this below content into the file

    [Unit]
    Description=Node Exporter
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    Restart=on-failure
    RestartSec=5s
    ExecStart=/usr/local/bin/node_exporter

    [Install]
    WantedBy=multi-user.target


(Optional) If you intend to monitor the client on an ongoing basis, use the systemctl enable command to automatically launch Node Exporter at boot time. This continually exposes the system metrics on port 9100. If Node Exporter is only intended for occasional use, do not use the command below.

    sudo systemctl enable node_exporter

Reload the systemctl daemon, start Node Exporter, and verify its status. The service should be active.

    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl status node_exporter

Use a web browser to visit port 9100 on the client node, for example, http://local_ip_addr:9100. A page entitled Node Exporter is displayed along with a link reading Metrics. Click the Metrics link and confirm the statistics are being collected. For a detailed explanation of the various statistics, see the Node Exporter Documentation.


###How to Configure Prometheus to Monitor Client Nodes

The client nodes are now ready for monitoring. To add clients to prometheus.yml, follow the steps below:

*On the monitoring server running Prometheus, open prometheus.yml for editing.*

    sudo nano /etc/prometheus/prometheus.yml

Locate the section entitled scrape_configs, which contains a list of jobs. It currently lists a single job named prometheus. This job monitors the local Prometheus task on port 9090. Beneath the prometheus job, add a second job having the job_name of remote_collector. Include the following information.

* A scrape_interval of 10s.
* Inside static_configs in the targets attribute, add a bracketed list of the IP addresses to monitor. Separate each entry using a comma.
* Append the port number :9100 to each IP address.
* To enable monitoring of the local server, add an entry for localhost:9100 to the list.

The entry should resemble the following example. Replace remote_addr with the actual IP address of the client.

    - job_name: "remote_collector"
      scrape_interval: 10s
      static_configs:
        - targets: ["remote_addr:9100"]

To immediately refresh Prometheus, restart the prometheus service.

    sudo systemctl restart prometheus

Using a web browser, revisit the Prometheus web portal at port 9090 on the monitoring server. Select Status and then Targets. A second link for the remote_collector job is displayed, leading to port 9100 on the client. Click the link to review the statistics.

###How to Install and Deploy the Grafana Server

Prometheus is now collecting statistics from the clients listed in the scrape_configs section of its configuration file. However, the information can only be viewed as a raw data dump. The statistics are difficult to read and not too useful.

Grafana provides an interface for viewing the statistics collected by Prometheus. Install Grafana on the same server running Prometheus and add Prometheus as a data source. Then install one or more panels for interpreting the data. To install and configure Grafana, follow these steps.

*Install some required utilities using apt.*

    sudo apt-get install -y apt-transport-https software-properties-common

*Import the Grafana GPG key.*

    sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key

*Add the Grafana “stable releases” repository.*

    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

*Update the packages in the repository, including the new Grafana package.*

    sudo apt-get update

Install the open-source version of Grafana.

>**Note**
> To install the Enterprise edition of Grafana, use the command `sudo apt-get install grafana-enterprise` instead.

    sudo apt-get install grafana

Reload the systemctl daemon.

    sudo systemctl daemon-reload

Enable and start the Grafana server. Using systemctl enable configures the server to launch Grafana when the system boots.

    sudo systemctl enable grafana-server.service
    sudo systemctl start grafana-server

Verify the status of the Grafana server and ensure it is in the active state.

    sudo systemctl status grafana-server

### How to Integrate Grafana and Prometheus

All system components are now installed, but Grafana and Prometheus are not set up to interact. The remaining configuration tasks, including adding Prometheus as the data source and importing a dashboard panel, can be accomplished using the Grafana web interface.

To integrate Grafana and Prometheus, follow the steps below:

* Using a web browser, visit port 3000 of the monitoring server. For example, enter http://local_ip_addr:3000, replacing local_ip_addr with the actual IP address. Grafana displays the login page. Use the user name admin and the default password password. Change the password to a more secure value when prompted to do so.

* After a successful password change, Grafana displays the Grafana Dashboard.

* To add Prometheus as a data source, click the gear symbol, standing for Configuration, then select Data Sources.

* At the next display, click the Add data source button.

* Choose Prometheus as the data source.

* For a local Prometheus source, as described in this guide, set the URL to http://localhost:9090. Most of the other settings can remain at the default values. However, a non-default Timeout value can be added here.

* When satisfied with the settings, select the Save & test button at the bottom of the screen.

* If all settings are correct, Grafana confirms the Data source is working.

### How to Import a Grafana Dashboard

A dashboard displays statistics for the client node using a more effective and standardized layout. It is certainly possible to create a custom dashboard. However, Prometheus has already created a dashboard to support the Node Exporter statistics. The Node Exporter Full dashboard neatly graphs most of the values collected from the client nodes. It is much less work to import this premade dashboard than to create a custom one.

To import the Node Exporter dashboard, follow the steps below:

>**Note**
>To create a custom dashboard, click on the Dashboard button, which resembles four squares. Then select + New Dashboard. Consult the Grafana guide to [Building a Dashboard](https://grafana.com/docs/grafana/latest/getting-started/build-first-dashboard/) for additional information.

*Visit the [Grafana Dashboard](https://grafana.com/grafana/dashboards/) Library. Enter `Node exporter` as the search term.*

- Make a note of the ID number or use the button to copy the ID to the clipboard. The ID of this board is currently 1860.
- Return to the Grafana dashboard. Select the Dashboard icon, consisting of four squares, and choose + Import.
- In the Import via grafana.com box, enter the ID 1860 from the previous step. Then select the Load button.
- At the next screen, confirm the import details. Choose Prometheus as the data source and click the Import button.

- The Node Exporter Full dashboard takes effect immediately. It displays the performance metrics and state of the client node, including the Memory, RAM, and CPU details. Several drop-down menus at the top of the screen allow users to select the host to observe and the time period to highlight.

    The following example demonstrates how a client reacts when stressed by a demanding Python program. The CPU Busy widget indicates how the CPU is pinned near the maximum. If this occurs during normal operating conditions, it potentially indicates more CPU power is required.

### Conclusion

Prometheus is a system monitoring application that polls client systems for key metrics. Each client node must use an exporter to collect and expose the requested data. Prometheus is most effective when used together with the Grafana visualization tool. Grafana imports the metrics from Prometheus and presents them using an intuitive dashboard structure.

To integrate the components, download and install Prometheus on a central server and configure Prometheus as a service. Install the Prometheus Node Exporter on each client to collect the data and configure Prometheus to poll the clients. Install Grafana on the same server as Prometheus and configure Prometheus as a data source. Finally, import a dashboard to display the metrics from the client. For more information on Prometheus, see the Prometheus Overview and Documentation. Grafana can be best understood by reading the Introduction to Grafana.


Credit goes to [Linode.com](https://www.linode.com/docs/guides/how-to-install-prometheus-and-grafana-on-ubuntu/)


# If you want to monitor multiple surver at a time, then you can use this configuration:


# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
      - targets: ["192.168.1.59:9090", "192.168.1.231:9090"]

  - job_name: "remote_collector"
    scrape_interval: 10s
    static_configs:
      - targets: ["192.168.1.59:9100"]

  - job_name: "remote_prometheus"
    scrape_interval: 10s
    static_configs:
      - targets: ["192.168.1.231:9100"]