{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.gateway;
  networks = attrValues cfg.networks;
  networkOpts = { name, ... }: {

    options = {

      name = mkOption {
        example = "wan-default";
        type = types.str;
        description = "Name of the network.";
      };

      interface = mkOption {
        example = "eth0";
        type = types.str;
        description = "Name of the interface.";
      };
      protocol = mkOption {
        example = "ip";
        type = types.str;
        description = "Name of the protocol.";
      };
      policy = mkOption {
        example = "wan-dhcp";
        type = types.str;
        description = "Name of the policy.";
      };
    };
    config = {
      name = mkDefault name;
    };
  };
in {
  imports = (mkIf cfg.enable { imports = [
    ./batman
    ./network
    ./rules
    ./dhcp
    ./dns
  ];}).content.imports;

  options = {
    services.gateway = {
      enable = mkEnableOption "the generic Gateway service";
    };

    services.gateway.networks = mkOption {
      default = {};
      example =
        { "wan-default" = {
            interface = "eth0";
            policy = "wan-dhcp";
            protocol = "ip";
          };
        };
      description = ''
        The configuration for each network on this gateway.
        Layer3 (ip) or Layer2 (batman) Network protocols, soon also your protocol is supported, just a PR away.
      '';
      type = with types; loaOf (submodule networkOpts);
    };
  };

  config = mkIf cfg.enable {
  };

}
