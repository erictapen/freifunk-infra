{ config, pkgs, ... }:{
  services.gateway = {
    enable = true;
    network = {
      # wan = {
      # 
      # };
      lan = {
        "ff-mesh" = {
          interface = "enp4s5";
          protocol = "batman-adv";
        };
      };
    };
  };
}
