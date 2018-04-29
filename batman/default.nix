{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.gateway;

  getAddress = ip: head (splitString "/" ip);
  getPrefix  = ip: toInt (elemAt (splitString "/" ip) 1);

  mapBatNets = f: mapAttrs' 
    f
    (filterAttrs 
      (n: v: hasPrefix "batman" v.protocol) 
      cfg.networks);
in

mkIf cfg.enable {
  boot = { 
    extraModulePackages = with config.boot.kernelPackages; [ batman_adv ];
    kernelModules = [ "batman_adv" ];
  };

  environment.systemPackages = with pkgs;[
    batctl
  ];
  systemd.services = mapBatNets (name: network: 
    nameValuePair
      "batman-${name}" 
      {
        after = [ "network-interfaces.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          ${pkgs.batctl}/bin/batctl -m "bat-${name}" interface add ${network.interface}
          ${pkgs.batctl}/bin/batctl -m "bat-${name}" gw_mode server
        '';
        serviceConfig.Type = "oneshot";
      }
  );
    
  networking.interfaces = mapBatNets (name: network: 
    nameValuePair
      "bat-${name}" 
      {
        ipAddress = "172.16.200.255";
        prefixLength = 24;
      }
  );

}  

  
