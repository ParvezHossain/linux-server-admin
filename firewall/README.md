## UFW (Uncomplicated Firewall)

#### Always write the firewall configuration from scratch

    sudo ufw status
    sudo ufw status verbose
    sudo ufw enable
    sudo ufw disable

###### Allow or Deny Specific Services

    sudo ufw allow OpenSSH
    sudo ufw allow http
    sudo ufw allow https

##### ufw config file

    sudo nano /etc/default/ufw

###### Allow Specific Ports

    sudo ufw allow 22/tcp  # Replace 22 with the port number you want to allow

##### Deny Specific Ports

    sudo ufw deny 8080/tcp  # Replace 8080 with the port number you want to deny

##### Get the all allowed list

    sudo ufw app list
    sudo ufw status numbered

##### Delete Rules

    sudo ufw delete <rule_number>
    sudo ufw delete allow http
    sudo ufw delete allow 80

##### Reset Firewall

    sudo ufw reset

##### Allow specific IP

    sudo ufw allow from 192.168.1.10

##### Allow from subnet

    sudo ufw allow from 192.168.1.0/24
    sudo ufw allow from 192.168.1.0/24 to any port 22

##### Connect to specific network interface

    sudo ufw allow in on eth0 to any port 80
    sudo ufw allow in on eth1 to any port 3306

### Creating Custom Chains

    sudo iptables -N my_custom_chain

### Adding Rules to Chains

    sudo iptables -A my_custom_chain -s <source_ip> -p tcp --dport <port_number> -j ACCEPT

### Forwarding Traffic between interfaces

    sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT

### Blocking Specific IPs

    sudo iptables -A INPUT -s <ip_address> -j DROP

### Logging Rules

    sudo iptables -A INPUT -p tcp --dport 22 -j LOG --log-prefix "SSH Traffic: "

### Network Address Translation (NAT)

    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

###  Port Redirection

Redirecting incoming traffic from one port to another:

    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

### Removing Rules

Removing specific rules by line number

    sudo iptables -D INPUT <line_number>

### Saving Changes

    sudo iptables-save > /etc/iptables/rules.v4

### Restoring Rules

    sudo iptables-restore < /etc/iptables/rules.v4
