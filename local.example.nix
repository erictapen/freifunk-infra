{ config, pkgs, ... }:

{
  services.gateway = {
    enable = true;
    networks = {
      "wan-default" = {
        interface = "enp0s25";
        policy = "wan-dhcp";
        protocol = "ip";
      };
      "lan-default" = {
        interface = "enp4s5";
        policy = "lan-batman";
        protocol = "batman";
      };
    };
    dhcp = {
      enable = true;
      interface = "bat-lan";
    };
  };
}
