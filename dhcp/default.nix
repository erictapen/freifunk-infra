{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gateway.dhcp;
  # Yes, this is dirty... (builds at evaluation)
  runScript = script: cidrRange: pkgs.runCommand
    "dhcp-config"
    {
      script = builtins.readFile script;
      passAsFile = [ "script" ];
    }
    ''
      ${pkgs.python3.withPackages (x: [x.netaddr])}/bin/python \
        $scriptPath ${cidrRange} > $out
    '';
  dhcp4Config = runScript ./generate-config.py cfg.dhcp4Range;
  dhcp6Config = runScript ./generate-config.py cfg.dhcp6Range;
  dhcp4ConfigText = builtins.readFile dhcp4Config;
  dhcp6ConfigText = builtins.readFile dhcp6Config;
  getGwIpAddress = dhcpRange: builtins.readFile (
    runScript ./get-gateway-address.py dhcpRange);
in {
  options.services.gateway.dhcp = {
    enable = mkEnableOption "a DHCP server";
    interface = mkOption {
      type = types.string;
      default = "eth1";
      example = "eth2";
      description = ''
         Client side interface (e.g. for Freifunk nodes).
      '';
    };
    dhcp4Range = mkOption {
      type = types.string;
      default = "172.16.200.0/24";
      example = "172.16.0.0/12";
      description = ''
        The IPv4 address range of the DHCP server.
      '';
    };
    dhcp6Range = mkOption {
      type = types.string;
      default = "fc00::/64";
      example = "fc00::/7";
      description = ''
        The IPv6 address range of the DHCP server.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces."${cfg.interface}" =
      let
        getAddress = ip: head (splitString "/" ip);
        getPrefix  = ip: toInt (elemAt (splitString "/" ip) 1);
      in {
      ipv4.addresses = [ {
        address = (getGwIpAddress cfg.dhcp4Range);
        prefixLength = (getPrefix cfg.dhcp4Range);
      } ];
      ipv6.addresses = [ {
        address = (getGwIpAddress cfg.dhcp6Range);
        prefixLength = (getPrefix cfg.dhcp6Range);
      } ];
    };
    services = {
      dhcpd4 = {
        enable = true;
        interfaces = [ cfg.interface ];
        extraConfig = ''
          ${dhcp4ConfigText}
        '';
      };
      dhcpd6 = {
        enable = true;
        interfaces = [ cfg.interface ];
        extraConfig = ''
          ${dhcp6ConfigText}
        '';
      };
    };
  };
}
