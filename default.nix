{ config, pkgs, lib, ...}:

with lib;

let
  cfg = config.services.gateway;
in {
  imports = (mkIf cfg.enable { imports = [
    ./batman
    ./network
    ./rules
  ];}).content.imports;

  options = {
    services.gateway = {
      enable = mkEnableOption "the generic Gateway service";
    };
  };

  config = mkIf cfg.enable {
  };
}
