{ config, pkgs, ... }:
let

  cfg = config.services.gateway;
in
{
   services.postgresql.enable = cfg.enable;
}
