{ config, pkgs, lib, ...}:

with lib;

let

  cfg = config.services.gateway;

in

{

  imports = [
    ./batman/.
  ];

  options = {
    services.gateway = {
      enable = mkOption {
        default = false;
        description = ''
        '';
        type = types.bool;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.hello
    ];
    
  };
}


