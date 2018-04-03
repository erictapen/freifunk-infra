{ config, pkgs, lib, ... }:

let
  # onboarding-repo = pkgs.fetchFromGitHub {
  #   owner = "FFS-Roland";
  #   repo = "FFS-Tools";
  #   rev = "0e393c7b1baf1f09dd594d4b801950420287f805";
  #   sha256 = "1834yj2vgs4dasdfnppc8iw8ll3yif948biq9hj0sbpsa2d8y44k";
  # };
  onboarder = pkgs.fetchFromGitHub {
    owner = "FFS-Roland";
    repo = "FFS-Tools";
    rev = "0e393c7b1baf1f09dd594d4b801950420287f805";
    sha256 = "1g9pzgvhq5crh4kh3yr0brbprbfks1frmz2w352jz7hnj7lkvhak";
  } + "/Onboarding";
  fastd-config = pkgs.writeTextFile {
    name = "fastd.conf";
    text = ''
      interface "vpn10299";
      bind any:10299 interface "eth0";
      status socket "/var/run/fastd-vpn10299.status";
      
      method "salsa2012+umac";
      method "null+salsa2012+umac";
      mtu 1340;
      
      peer limit 1;
      
      on verify    "${onboarder}/vpnXXXXX-on-verify.sh";
      on establish "${onboarder}/vpnXXXXX-on-establish.sh";

      # Public: 6b02214cb4eab0ea90316e1ca5cb37039b4eae4665ccd291887456b7f3f7b73d
      secret "10f058c6744c3d3f5344521367fbb74faea131ccb7f4d3eb2411a61c7c18604d";
    '';
  };
  # on verify    "${onboarding-repo}/vpnXXXXX-on-verify.sh";
  # on establish "${onboarding-repo}/vpnXXXXX-on-establish.sh";
in
{

  networking.firewall = {
    allowedTCPPorts = [ 10299 ];
    allowedUDPPorts = [ 10299 ];
  };
 
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ batman_adv ];
    kernelModules = [ "batman_adv" ];
  };

  environment.systemPackages = with pkgs;[
    batctl
    fastd
    vim
  ];
 
  systemd.services."batman" = {
    after = [ "network-interfaces.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.batctl}/bin/batctl -m "batman" interface add eth0
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.services."fastd" = {
    after = [ "network-interfaces.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.fastd}/bin/fastd --config ${fastd-config}
    '';
    # serviceConfig.Type = "oneshot";
  };

}
