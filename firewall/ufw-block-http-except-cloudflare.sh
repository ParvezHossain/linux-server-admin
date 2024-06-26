# This is a shell script that will allow your to block all http and https traffic from the internet and allow only cloudflares IP Block. It will then generate a ufw allow command for all of Cloudflares IP Block.

# This script is designed for debian based linux servers using the UFW (Uncomplicated Firewall)

# Using this script properly will essentially give your server the best DDoS protection as it will force all http/https traffic through cloudflare.


#!/bin/sh
# This file had been modified by clusterednetworks.com
# 2018-11-20
# Copyright (C) 2018  <info@clusterednetworks.com>
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
# 
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
# This script will fetch cloudflare IP Blocks and add them to allow from in UFW
# works on debian based Linux
DIR="$(dirname $(readlink -f $0))"
cd $DIR
wget https://www.cloudflare.com/ips-v4 -O ips-v4.tmp
wget https://www.cloudflare.com/ips-v6 -O ips-v6.tmp
mv ips-v4.tmp ips-v4
mv ips-v6.tmp ips-v6

for cfip in `cat ips-v4`; do ufw allow proto tcp from $cfip to any port 80,443; done
for cfip in `cat ips-v6`; do ufw allow proto tcp from $cfip to any port 80,443; done

ufw reload > /dev/null

# OTHER EXAMPLE RULES
# Examples to restrict to port 80
#for cfip in `cat ips-v4`; do ufw allow from $cfip to any port 80 proto tcp; done
#for cfip in `cat ips-v6`; do ufw allow from $cfip to any port 80 proto tcp; done

# Examples to restrict to port 443
#for cfip in `cat ips-v4`; do ufw allow from $cfip to any port 443 proto tcp; done
#for cfip in `cat ips-v6`; do ufw allow from $cfip to any port 443 proto tcp; done