{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gateway.dns;
  dhcpCfg = config.services.gateway.dhcp;
  dhcpInterface = config.networking.interfaces."${dhcpCfg.interface}";
  getInterfaceAddresses = interface:
    map (l: l.address) interface.ipv4.addresses
    ++ map (l: l.address) interface.ipv4.addresses;
in {
  options.services.gateway.dns = {
    enable = mkEnableOption "a DNS server";
    backend = mkOption {
      type = types.enum [ "unbound" "pdns-recursor" ];
      default = "unbound";
      example = "pdns-recursor";
      description = ''
        The backend for the DNS server.
      '';
    };
  };

  config = mkIf (dhcpCfg.enable && cfg.enable) {
    networking.firewall.allowedUDPPorts = [ 53 ];
    services = {
      unbound = mkIf (cfg.backend == "unbound") {
        enable = true;
        allowedAccess = [ dhcpCfg.dhcp4Range dhcpCfg.dhcp6Range ];
        interfaces = [ "127.0.0.1" "::1" ] ++ getInterfaceAddresses dhcpInterface;
      };
      pdns-recursor = mkIf (cfg.backend == "pdns-recursor") {
        enable = true;
        api.allowFrom = [ "127.0.0.0/8" "::1" ];
        dns.address = "127.0.0.1,::1"
          + foldl (a: b: a+","+b) "" (getInterfaceAddresses dhcpInterface);
        dns.allowFrom = [ "127.0.0.0/8" "::1" ]
          ++ [ dhcpCfg.dhcp4Range dhcpCfg.dhcp6Range ];
      };
    };
  };
}
