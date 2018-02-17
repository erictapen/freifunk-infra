---
title: Readme for NixOS Gateway
status: experimental
---

This repository enables option on NixOS for functioning as a gateway.

# Deployment

Clone this repository and add this code to your  global NixOS conf, e.g. in your `/etc/nixos/configuration.nix`:
```
git clone https://github.com/erictapen/freifunk-infra.git /etc/nixos/include/global
```

```
imports = [
  ... stuff you already had there
  ./include/global/default.nix
  ./include/local/default.nix
];
```

In your `/etc/include/local/default.nix` specify your settings for this gateway.
```
# NixOS local gateway configuration
{ config, pkgs, ... }:

services.gateway.enable = true;
services.gateway.network.global.wan.interface = "enp0s25";
services.gateway.network.local.lan.interface = "enp4s5";
services.gateway.network.local.batman.interface = "enp0s25.9";
```
