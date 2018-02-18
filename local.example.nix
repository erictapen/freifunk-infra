{ config, pkgs, ... }:

{
  services.gateway = {
    enable = true;
    networks = {
      "wan-default" = {
        interface = "enp0s25";
        protocol = "freifunk-stuttgart";
      };
      "vpn-ffs" = {
        interface = "enp0s25";
      };
      "lan-default" = {
        interface = "enp4s5";
        policy = "lan-dhcp";
        protocol = "ip";
      };
    };
    dhcp = {
      enable = true;
      interface = "bat-lan";
    };
  };
}
