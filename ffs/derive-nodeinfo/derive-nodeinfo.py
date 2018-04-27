#!/usr/bin/env python3

import argparse
import json

parser = argparse.ArgumentParser(description="Generate a nodeinfo JSON dict for a Freifunk node.")
parser.add_argument("--hostname", dest="HOSTNAME", action="store", required=True, help="Name of the Freifunk node.")
parser.add_argument("--contact", dest="CONTACT", action="store", required=True, help="Contact address, e.g. an mail address.")
parser.add_argument("--nodeid", dest="NODEID", action="store", required=True, help="Node ID, e.g. ead358ad8730.")
parser.add_argument("--zip", dest="ZIP", action="store", required=True, help="A ZIP code, e.g. 72074.")

args = parser.parse_args()

mac = ":".join(a+b for a,b in zip(args.NODEID[::2], args.NODEID[1::2]))

ipv6_long = 'fe80::' + hex(int(mac[0:2],16) ^ 0x02)[2:]+mac[3:8]+'ff:fe'+mac[9     :14]+mac[15:17]

# TODO: derive proper IPv6 addresses
ipv6 = ipv6_long
ipv6_small = ipv6_long

print(json.dumps({
  "software": {
    "autoupdater": {
      "branch": "stable",
      "enabled": True
    },
    "batman-adv": {
      "version": "2016.2",
      "compat": 15
    },
    "fastd": {
      "version": "v18",
      "enabled": True
    },
    "firmware": {
      "base": "gluon-v2016.2.7",
      "release": "1.3+2017-09-13-g.d722c26-s.b0e5e48"
    },
    "status-page": {
      "api": 1
    }
  },
  "network": {
    "addresses": [
      ipv6,
      ipv6_long,
      ipv6_small,
    ],
    "mesh": {
      "bat0": {
        "interfaces": {
        }
      }
    },
    "mac": mac,
  },
  "location": {
    "zip": "72074"
  },
  "owner": {
    "contact": "anfrage@freifunk-neckaralb.de"
  },
  "system": {
    "site_code": "ffs"
  },
  "node_id": "8416f9e8a8b8",
  "hostname": "ffs-tue-elefantengehege",
  "hardware": {
    "model": "TP-Link TL-WR1043N/ND v4",
    "nproc": 1
  }
}))

