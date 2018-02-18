{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gateway.dns;
  dhcpCfg = config.services.gateway.dhcp;
  dhcpInterface = config.networking.interfaces."${dhcpCfg.interface}";
  getInterfaceAddresses = interface:
    map (l: l.address) interface.ip4
    ++ map (l: l.address) interface.ip6;
in {
  options.services.gateway.dns = {
    enable = mkEnableOption "a DNS server";
  };

  config = mkIf (dhcpCfg.enable && cfg.enable) {
    networking.firewall.allowedUDPPorts = [ 53 ];
    services.unbound = {
      enable = true;
      allowedAccess = [ dhcpCfg.dhcp4Range dhcpCfg.dhcp6Range ];
      interfaces = [ "127.0.0.1" "::1" ] ++ getInterfaceAddresses dhcpInterface;
    };
  };
}
