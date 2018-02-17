{ config, pkgs, ...}:{

  with lib;
 
  let
 
    cfg = config.services.gateway;
 
  in
 
  {
 
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
    };


}
