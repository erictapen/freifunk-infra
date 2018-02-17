#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.netaddr

# Parameters: An IPv4 or IPv6 subnet in CIDR notation

import sys
import netaddr

if len(sys.argv) != 2:
    sys.stderr.write("Error: Expected parameters: 1"
      + ", actual parameters: {}\n".format(len(sys.argv)-1))
    sys.stderr.write("Error: You must specify a subnet in CIDR notation.\n")
    exit(1)

ipSubnet = netaddr.IPNetwork(sys.argv[1])
ipVersion = ipSubnet.ip.version

gwIp = netaddr.IPAddress(ipSubnet.last-1)
rangeStart = netaddr.IPAddress(ipSubnet.first+1)
rangeEnd   = netaddr.IPAddress(ipSubnet.last-2)

if ipVersion == 4:
    print("option routers {};".format(gwIp))
    print("option domain-name-servers {};".format(gwIp))
    print("option subnet-mask {};".format(ipSubnet.netmask))
    print("option broadcast-address {};".format(ipSubnet.broadcast))
    print("subnet {} netmask {} {{".format(ipSubnet.network,ipSubnet.netmask))
    print("  range {} {};".format(rangeStart,rangeEnd))
    print("}")
else:
    print("option dhcp6.name-servers {};".format(gwIp))
    print("subnet6 {} {{".format(ipSubnet))
    print("  range6 {} {};".format(rangeStart,rangeEnd))
    print("}")
