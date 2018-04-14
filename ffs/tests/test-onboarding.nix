# Dieser Test soll das Onboarding bei FFS testen. Ein Onboarder mit den
# Skripten von https://github.com/FFS-Roland/FFS-Tools fährt hoch, ein Node
# versucht sich gegen den Onboarder zu verbinden.
import <nixpkgs/nixos/tests/make-test.nix> ({ pkgs, ...}:

{
  name = "onboarding";

  nodes = {

    ffsOnboarder =
      { config, pkgs, lib, ... }:
      {
        imports = [
          ./onboarder.nix
        ];
      };

    ffsNode =
      { config, pkgs, lib, ... }:
      {
        imports = [
          ../default.nix
        ];

        services.freifunk-stuttgart = {
          enable = true;
          kontaktAdresse = "mail@example.org";
          mac = "89:43:3d:c6:f6:09";
          fastd-peer-onboarder = ''
            key "6b02214cb4eab0ea90316e1ca5cb37039b4eae4665ccd291887456b7f3f7b73d";
            remote ipv4 "ffsOnboarder" port 10299;
          '';
        };
      };

  };

  testScript = ''
    $ffsOnboarder->start;

    $ffsOnboarder->waitForUnit("fastd.service");

    # This would fail:
    # $ffsOnboarder->waitForUnit("batman.service");

    $ffsOnboarder->waitUntilSucceeds("batctl -m batman interface");
    $ffsOnboarder->fail("batctl interface");


    $ffsNode->start;
    $ffsNode->waitForFile("/var/lib/freifunk-vpn/ffs/fastd_secret.conf");
  '';
  

})
