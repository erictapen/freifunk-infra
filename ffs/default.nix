{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.freifunk-stuttgart;

  fastdConfig = builtins.toFile "fastd.config" ''

  '';

  nodeid = builtins.replaceStrings [":"] [""] cfg.mac;

  # TODO berechnen anhand von https://en.wikipedia.org/wiki/IPv6_address#Modified_EUI-64
  ipv6small = "";
  ipv6medium = "";

  nodeinfo = builtins.toFile "nodeinfo.json" (builtins.toJSON {
    software = {
      firmware = {
        # base = "gluon-v2016.2.7";
        release ="1.3+2017-09-13-g.d722c26-s.b0e5e48";
        isGluon = false;
      };
    };
    owner = {
      contact = cfg.kontaktAdresse;
      #contact = "mail@example.org";
    };
    "node_id" = nodeid;
  });

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
in

{
  options = {
    services.freifunk-stuttgart = {
      enable = mkEnableOption "Freifunk Stuttgart VPN";

      kontaktAdresse = mkOption {
        type = types.str;
        example = "mail@example.org";
        description = "Kontaktmöglichkeit, mit der der/die \"Knotenbetreiber*in\" erreicht werden kann.";
      };

      # See https://gluon.readthedocs.io/en/v2017.1.5/dev/mac_addresses.html for this
      mac = mkOption {
        type = types.str;
        example = "89:43:3d:c6:f6:09";
        description = "MAC-Adresse, die gleichzeitig auch Node-ID ist.";
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
        file = nodeinfo;
        urlPath = "/cgi-bin/nodeinfo";
      }];
    };

    # networking.interfaces."ffs-mesh-vpn".macAddress = cfg.mac;

  };
}
