{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.gateway;
  lanInterface = "br-client-local";
  wanInterface = cfg.networks.wan-default.interface;
  openTCPPorts = [
    22
    80
    111
    443
  ];
  openUDPPorts = [
    53
    67
    69
    123
    111
  ];

in
mkIf cfg.enable {

  boot =
  {
    kernel.sysctl =
    {
      "net.core.default_qdisc" = "fq_codel";
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.use_tempaddr" = 0;
      "net.ipv6.conf.default.use_tempaddr" = 0;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.rp_filter" = 2;
    };
  };

  networking =
  {
    firewall = {
      enable = true;
      allowedTCPPorts = openTCPPorts;
      allowedTCPPortRanges = [
      # { from = 6543; to = 6544; } # MythTV
      # { from = 9101; to = 9103; } # bacula
      ];
      allowedUDPPorts = openUDPPorts;
    # allowedUDPPortRanges = [
    #  { from = 1024; to = 655; }
    #  { from = 1714; to = 1764; }
    # ];
      allowPing = true;
    # rejectPackets = false;
    # extraCommands =
    # ''
    #  ip46tables -A nixos-fw -i ve-+ -p tcp --dport 4713 -j nixos-fw-accept;
    #  ip46tables -A nixos-fw -i ve-+ -p tcp --dport 631 -j nixos-fw-accept;
    #  ip46tables -A nixos-fw -i ve-+ -p udp --dport 631 -j nixos-fw-accept;
    #  ip46tables -A nixos-fw -i ve-+ -p udp --dport 53 -j nixos-fw-accept;
    #  ip46tables -A nixos-fw -i ve-+ -p tcp --dport 53 -j nixos-fw-accept;
    #  '';
    #  ";
    };
    interfaces = {
      ${lanInterface} = {
        name = "${lanInterface}";
        useDHCP = false;
      };
      ${wanInterface} = {
        name = "${wanInterface}";
        useDHCP = true;
      };
    };
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
    nat = {
      enable = true;
    # externalInterface =  "ppp0";
      externalInterface =  "${wanInterface}";
      internalInterfaces = [ "${lanInterface}" ];
      forwardPorts = [
    #   { destination = "192.168.1.212:873"; sourcePort = 873; }
    #   { destination = "192.168.1.1:9050"; sourcePort = 9050; }
    #   { destination = "192.168.1.1:22"; sourcePort = 22; }
      ];
    };
  };

}
