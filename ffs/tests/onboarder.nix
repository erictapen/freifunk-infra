{ config, pkgs, lib, ... }:

let
  onboarder = pkgs.stdenv.mkDerivation {
    name = "onboarder";

    src = pkgs.fetchFromGitHub {
      owner = "erictapen";
      repo = "FFS-Tools";
      rev = "41bb7bab5ae87daa6ddf9351993d102213d36e65";
      sha256 = "0m4f7v51m1qnjzs36rbxscix16if7qygr8kvhdp9p266ac1f0gv7";
    };

    patches = [
      (import ./make-binary-paths-patch.nix { inherit pkgs; })
      (builtins.toFile "debug.patch" ''
        diff --git a/Onboarding/vpnXXXXX-on-establish.sh b/Onboarding/vpnXXXXX-on-establish.sh
        index 5fe57d0..8147474 100755
        --- a/Onboarding/vpnXXXXX-on-establish.sh
        +++ b/Onboarding/vpnXXXXX-on-establish.sh
        @@ -39,6 +39,8 @@
         #                                                                                         #
         ###########################################################################################
        
        +touch /var/freifunk/on-establish-ran
        +
         LOGFILE=/var/freifunk/logs/''${INTERFACE}_$(date +%y%m%d)_established.log
        
        
        diff --git a/Onboarding/vpnXXXXX-on-verify.sh b/Onboarding/vpnXXXXX-on-verify.sh
        index 8fffb0f..45ad114 100755
        --- a/Onboarding/vpnXXXXX-on-verify.sh
        +++ b/Onboarding/vpnXXXXX-on-verify.sh
        @@ -42,6 +42,8 @@
         #                                                                                         #
         ###########################################################################################
        
        +touch /var/freifunk/on-verify-ran
        +
         LOGFILE=/var/freifunk/logs/wpnXXXXX_$(date +%y%m%d)_verify.log
        
         #exit 1    # for blocking during test phase only - will be removed later!
        
      '')
    ];

    buildInputs = with pkgs.python3Packages;[
      psutil
      GitPython
      dns
      shapely
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp Onboarding/ffs-Onboarding.py $out/bin
      cp Onboarding/vpnXXXXX-on-establish.sh $out/bin
      cp Onboarding/vpnXXXXX-on-verify.sh $out/bin
    '';
  };

  fastd-config = pkgs.writeTextFile {
    name = "fastd.conf";
    text = ''
      log level debug2;

      interface "vpn10299";
      bind any:10299 interface "eth0";
      status socket "/var/run/fastd-vpn10299.status";
      
      method "salsa2012+umac";
      method "null+salsa2012+umac";
      mtu 1340;
      
      peer limit 1;
      
      on verify    "${onboarder}/bin/vpnXXXXX-on-verify.sh";
      on establish "${onboarder}/bin/vpnXXXXX-on-establish.sh";

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
    onboarder
  ];

  systemd.services = {
    "fastd" = {
      after = [ "network.target" ];
      wantedBy = [ "batman.service" ];
      path = with pkgs;[
        procps
      ];
      preStart = ''
        mkdir -p /var/freifunk/logs/
        mkdir -p /var/freifunk/peers-ffs/
        mkdir -p /var/freifunk/database/
        mkdir -p /var/freifunk/blacklist/
      '';
      serviceConfig = {
        ExecStart = ''
          ${pkgs.fastd}/bin/fastd --config ${fastd-config}
        '';
      };
      # serviceConfig.Type = "oneshot";
    };
 
    "batman" = {
      after = [ "fastd.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.batctl}/bin/batctl -m "batman" interface add vpn10299
      '';
    };
  };

}
