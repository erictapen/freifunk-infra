{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.gateway;

  getAddress = ip: head (splitString "/" ip);
  getPrefix  = ip: toInt (elemAt (splitString "/" ip) 1);
in

mkIf cfg.enable {
  boot = { 
    extraModulePackages = with config.boot.kernelPackages; [ batman_adv netatop ];
    kernelModules = [ "batman_adv" ];
  };

  environment.systemPackages = with pkgs;[
    batctl
  ];

  systemd.services = {
    "batman-lan" = {
      after = [ "network-interfaces.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        # TODO enp4s5 kann später z.B. durch cfg.network.lan."ff-local".interface ersetzt werden 
        ${pkgs.batctl}/bin/batctl -m "bat-lan" interface add enp4s5
        ${pkgs.batctl}/bin/batctl -m "bat-lan" gw_mode server
      '';
      serviceConfig.Type = "oneshot";
    };
    
    # "batman-wan" = {
    # };
  };

  networking.interfaces."bat-lan" = {
    ipAddress = "172.16.200.255";
    prefixLength = 24;
  };
  
}
