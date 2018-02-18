---
title: Readme for NixOS Gateway
status: experimental
---

This repository enables NixOS for functioning as a gateway.

# Deployment

Clone this repository:
```
git clone https://github.com/erictapen/freifunk-infra.git /etc/nixos/include/global
```

Then add this code to your global NixOS conf, e.g. in your `/etc/nixos/configuration.nix`:
```
imports = [
  ... stuff you already had there
  ./include/global/default.nix
  ./include/local/default.nix
];
```

In your `/etc/include/local/default.nix` specify your settings for this gateway.
An example configuration is found in `local.example.nix`.
```
# NixOS gateway configuration
{ config, pkgs, ... }:

services.gateway.enable = true;
services.gateway.network."wan-default".interface = "enp0s25";
services.gateway.network."wan-default".policy = "wan-dhcp";
services.gateway.network."vpn-ffs".interface = "br-wan";
services.gateway.network."vpn-ffs".policy = "freifunk.stuttgart";
services.gateway.network."ff-client-local".interface = "enp4s5.6";
services.gateway.network."ff-client-local".rules.directEgress = [ "22" "443" ];
services.gateway.network."ffs-client-global".interface = "enp4s5.711";
services.gateway.network."lan-default".interface = "enp4s5";
services.gateway.network."lan-default".protocol = "ip";
services.gateway.network."ff-mesh".interface = "enp4s5.9";
services.gateway.network."ff-mesh".protocol = "batman-adv-2017.4";
```

This is experimental yet.
