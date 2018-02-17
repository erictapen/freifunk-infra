{ config, pkgs, lib, ... }:
with lib;
let

  cfg = config.services.gateway;
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
        ${pkgs.batctl}/bin/batctl -m "bat-lan" if add enp4s5
      '';
      serviceConfig.Type = "oneshot";
    };
    # "batman-wan" = {
    # };
  };
}
