{ config, pkgs, ... }:

let
  secrets = (import ../../secrets);
in
{
  imports = [
    ./hardware-configuration.nix
    ./systemPackages.nix
    ./services/openssh.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda"; 


  time.timeZone = "Europe/Amsterdam";

  environment.variables = {
    editor = "vim";
  };

  networking = {
    hostName = "testing";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        (builtins.head config.services.openssh.listenAddresses).port
      ];
      allowedUDPPorts = [ ];
    };
    nameservers = [
      "94.186.254.1"
      "94.186.253.1"
    ];
    defaultGateway.address = "94.186.181.113";
    interfaces.enp0s5.ipAddress = "94.186.181.116";
    interfaces.enp0s5.prefixLength = 28;
  };

  users.users.root = {
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      secrets.sshPublicKeys.justin
      secrets.sshPublicKeys.jo1
      secrets.sshPublicKeys.jo2
    ];
  };

  system.stateVersion = "17.03";

}
