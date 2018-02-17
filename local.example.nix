{ config, pkgs, ... }:{
  services.gateway = {
    enable = true;
    network = {
      "wan-dhcp" = {
        interface = "enp0s25";
        policy = "wan-dhcp";
        protocol = "ip";
      };
      "ff-mesh" = {
        interface = "enp4s5";
        protocol = "batman-adv";
      };
    };
  };
}
