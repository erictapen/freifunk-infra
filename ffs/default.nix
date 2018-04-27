{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.freifunk-stuttgart;

  # nodeinfo = builtins.toFile "nodeinfo.json" (builtins.toJSON {
  #   software = {
  #     firmware = {
  #       # base = "gluon-v2016.2.7";
  #       release ="1.3+2017-09-13-g.d722c26-s.b0e5e48";
  #       isGluon = false;
  #     };
  #   };
  #   owner = {
  #     contact = cfg.kontaktAdresse;
  #     #contact = "mail@example.org";
  #   };
  #   "node_id" = nodeid;
  # });

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

  # Die Maximum Transfer Unit der fastd-Verbindung  
  fastd-mtu = 1340;

  # fastd config for the Onboarding peer
  fastd-peer-onboarder = builtins.toFile "offloader.conf" cfg.fastd-peer-onboarder;

  # The static part of the fastd config file. The dynamic part contains the VPN keys.
  fastd-static-config = builtins.toFile "fastd.conf" ''
    log level debug2;

    interface "ffs-mesh-vpn";
    mtu ${builtins.toString fastd-mtu};
    include "/var/lib/freifunk-vpn/ffs/fastd_secret.conf";
    include peer "${fastd-peer-onboarder}" as "onboarder";

    # TODO remove?
    # Support salsa2012+umac and null methods, prefer salsa2012+umac
    method "salsa2012+umac";
    method "null";
    drop capabilities no;

    bind 0.0.0.0:10000;

    # Include peers from the directory 'peers'
    # include peers from "peers";
  '';
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
    ];

    services.httpd = {
      enable = true;
      adminAddr = cfg.kontaktAdresse;
      servedFiles = [{
        file = "/var/lib/freifunk-vpn/ffs/nodeinfo";
        urlPath = "/cgi-bin/nodeinfo";
      }];
      listen = [{
        ip = ":::";
        port = 80;
      }];
    };

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

    # This service checks wether state like fastd secret and a node ID is
    # available and if not, generates them. Delete /var/lib/freifunk-vpn/ffs to
    # force the generation of a new state. Do NOT delete only certain parts of
    # it, as inconsistent state may cause troubles with the onboarding process.
    # 
    # In order to make corrupting state more difficult, the nodeinfo JSON will
    # be derived from the node ID every time the service starts.
    systemd.services = {
      "ffs-generate-state" = {
        serviceConfig.Type = "oneshot";
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
          generate-nodeinfo.py \
            --zip '${cfg.zip}' \
            --contact '${cfg.kontaktAdresse}' \
            --hostname '${cfg.hostname}' \
            --nodeid "$(cat /var/lib/freifunk-vpn/ffs/nodeid)"
        '';
      };
      "ffs-fastd" = {
        after = [ "ffs-generate-state.service" ];
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
