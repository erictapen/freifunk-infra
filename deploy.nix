{
  network.description = "Freifunk infrastructure";

  testing = { config, pkgs, ... }:
  {
    deployment = {
      targetEnv = "none";
      targetHost = "94.186.181.116";
      targetPort = 8765;
    };

    imports = [ ./hosts/testing/configuration.nix ];
  };

}

