#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.netaddr

# Parameters: An IPv4 or IPv6 subnet in CIDR notation
# Returns the IP address of the gateway (DHCP server), which is the last
# available address within the given subnet.

import sys
import netaddr

if len(sys.argv) != 2:
    sys.stderr.write("Error: Expected parameters: 1"
      + ", actual parameters: {}\n".format(len(sys.argv)-1))
    sys.stderr.write("Error: You must specify a subnet in CIDR notation.\n")
    exit(1)

ipSubnet = netaddr.IPNetwork(sys.argv[1])
gwIp = netaddr.IPAddress(ipSubnet.last-1)
sys.stdout.write(str(gwIp))
