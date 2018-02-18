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
      "local" = {
        interface = "enp4s5";
        policy = "lan-batman";
        protocol = "batman";
      };
    };
    dhcp = {
      enable = true;
      interface = "br-client-local";
    };
    dns = {
      enable = true;
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
