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
    dns = {
      enable = true;
      backend = "pdns-recursor";
    };
  };

  networking.vlans =
  {
    "enp4s5.6" = {
      id = 6;
      interface = "enp4s5";
    };
    "enp4s5.9" = {
      id = 9;
      interface = "enp4s5";
    };
  };

}
