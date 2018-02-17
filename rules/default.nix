{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.gateway;
in
mkIf cfg.enable {
#  services.bird.enable = true;
}
