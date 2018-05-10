{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.freifunk-stuttgart;

  # TODO: https://github.com/hopglass/node-respondd
  # respondd = pkgs.stdenv.mkDerivation {
  #   name = "respondd";
  #   
  #   src = (pkgs.fetchFromGitHub {
  #     owner = "freifunk-gluon";
  #     repo = "packages";
  #     rev = "53a659abf8809f36f2da130bb920a41ac6b698cb";
  #     sha256 = "1csmjvapxc4zarbakjafyqy5kxbgib4r69i70kd8jnfsdjzjm2m8";
  #   }) + "/net/respondd/src";

  #   buildInputs = with pkgs;[ cmake pkgconfig json_c ];
  # };

  derive-nodeinfo = pkgs.stdenv.mkDerivation {
    name = "derive-nodeinfo";
    buildInputs = with pkgs; [ python3 ];
    dontBuild = true;
    src = ./derive-nodeinfo; 
    installPhase = ''
      mkdir -p $out/bin
      cp derive-nodeinfo.py $out/bin/
    '';
  }; 

  # Die Maximum Transfer Unit der fastd-Verbindung  
  fastd-mtu = 1340;

  # fastd config for the Onboarding peer
  fastd-peer-onboarder = builtins.toFile "offloader.conf" cfg.fastd-peer-onboarder;

  # TODO for some reason, the node does not execute this script...
  fastd-on-up = pkgs.writeTextFile {
    name = "fastd-on-up";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      ${pkgs.iproute}/bin/ip link set ffs-mesh-vpn address $(${pkgs.jq}/bin/jq -r ."network"."mac" /var/lib/freifunk-vpn/ffs/www/cgi-bin/nodeinfo)
      for ipv6 in $(${pkgs.jq}/bin/jq -r .network.addresses[] /var/lib/freifunk-vpn/ffs/www/cgi-bin/nodeinfo)
      do
        ${pkgs.iproute}/bin/ip addr add $ipv6/64 dev ffs-mesh-vpn
      done 
    '';
  };

  # The static part of the fastd config file. The dynamic part contains the VPN keys.
  fastd-static-config = pkgs.writeTextFile {
    name = "fastd.conf"; 
    text = ''
      log level debug2;

      interface "ffs-mesh-vpn";
      mtu ${builtins.toString fastd-mtu};
      include "/var/lib/freifunk-vpn/ffs/fastd_secret.conf";
      include peer "${fastd-peer-onboarder}" as "onboarder";

      # TODO remove?
      # Support salsa2012+umac and null methods, prefer salsa2012+umac
      method "salsa2012+umac";
      method "null";
      drop capabilities yes;

      bind 0.0.0.0:10000;

      on up "${fastd-on-up}";
    '';
  };

in

{
  options = {
    services.freifunk-stuttgart = {
      enable = mkEnableOption "Freifunk Stuttgart VPN";

      hostname = mkOption {
        type = types.str;
        example = "ffs-tue-fablab-neckar-alb";
        description = "Name des Freifunkknoten.";
      };

      kontaktAdresse = mkOption {
        type = types.str;
        example = "mail@example.org";
        description = "Kontaktmöglichkeit, mit der der/die \"Knotenbetreiber*in\" erreicht werden kann.";
      };

      zip= mkOption {
        type = types.str;
        example = "72074";
        description = "Postleitzahl, in der der Node verortet werden soll. Dies ist wichtig für die Zuweisung des Segmentes";
      };

      fastd-peer-onboarder = mkOption {
        type = types.str;
        # TODO stimmt der key?
        default = ''
          key "1af6a5d41d866823e5712e8d9af42080397ad52bdd8664a11ca94225629398a3";
          remote ipv4 "gw07.gw.freifunk-stuttgart.de" port 10299;
        '';
        description = "fastd-Peer-Config, die Key und Ort des Onboarders angibt. Muss eigentlich nur für Tests geändert werden.";
      };

    };
  };

  config = mkIf cfg.enable {

    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ batman_adv ];
      kernelModules = [ "batman_adv" ];
    };

    environment.systemPackages = with pkgs;[
      batctl
      fastd
      jq
    ];

    networking.firewall = {
      allowedTCPPorts = [
        80 # HTTP
      ];
    };

    environment.etc = {
      "freifunk-vpn/ffs/fastd.conf" = {
        source = fastd-static-config;
      };
    };

    systemd.services = {

      # This service checks wether state like fastd secret and a node ID is
      # available and if not, generates them. Delete /var/lib/freifunk-vpn/ffs
      # to force the generation of a new state. Do NOT delete only certain
      # parts of it, as inconsistent state may cause troubles with the
      # onboarding process.
      # In order to make corrupting state more difficult, the nodeinfo JSON
      # will be derived from the node ID every time the service starts.
      "ffs-generate-state" = {
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        after = [ "network-interfaces.target" ];
        wantedBy = [ "ffs-fastd.service" ];
        script = ''
          if [ ! -d /var/lib/freifunk-vpn/ffs/fastd_secret.conf ]; then
            echo "Generate new fastd secret..."
            mkdir -p /var/lib/freifunk-vpn/ffs/
            FASTD_SEC=$(${pkgs.fastd}/bin/fastd --generate-key --machine-readable)
            echo "secret \"$FASTD_SEC\";" > /var/lib/freifunk-vpn/ffs/fastd_secret.conf
          fi
          if [ ! -d /var/lib/freifunk-vpn/ffs/nodeid ]; then
            echo "Generate new node ID..."
            ${pkgs.xxd}/bin/xxd -l 6 -p /dev/random > /var/lib/freifunk-vpn/ffs/nodeid
          fi
          echo "Derive MAC and IPv6 addresses from nodeid..."
          mkdir -p /var/lib/freifunk-vpn/ffs/www/cgi-bin
          ${derive-nodeinfo}/bin/derive-nodeinfo.py \
            --zip '${cfg.zip}' \
            --contact '${cfg.kontaktAdresse}' \
            --hostname '${cfg.hostname}' \
            --nodeid "$(cat /var/lib/freifunk-vpn/ffs/nodeid)" \
          > /var/lib/freifunk-vpn/ffs/www/cgi-bin/nodeinfo

          echo "State generated."
        '';
      };

      "ffs-httpd" = {
        after = [ "network-interfaces.target" "ffs-generate-state.service" ];
        wantedBy = [ "ffs-fastd.service" ];
        preStart = ''
          mkdir -p /var/lib/freifunk-vpn/ffs/www/cgi-bin
        '';
        serviceConfig = {
          ExecStart = ''
            ${pkgs.darkhttpd}/bin/darkhttpd /var/lib/freifunk-vpn/ffs/www/ \
              --no-listing \
              --ipv6 \
              --chroot \
              --no-server-id
          '';
        };
      };

      "ffs-fastd" = {
        after = [ "ffs-generate-state.service" "ffs-httpd.service" ];
        wantedBy = [ "ffs-batman.service" ];
        script = ''
          exec ${pkgs.fastd}/bin/fastd -c /etc/freifunk-vpn/ffs/fastd.conf
        '';
      };

      "ffs-batman" = {
        after = [ "ffs-fastd.service" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          ${pkgs.batctl}/bin/batctl -m batman interface add ffs-mesh-vpn
        '';
      };
    };

  };
}
