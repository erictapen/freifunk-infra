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
        environment.systemPackages = with pkgs; [
          fastd
        ];
      };

  };

  testScript = ''
    $ffsOnboarder->start;

    $ffsOnboarder->waitForUnit("fastd.service");

    # This would fail:
    # $ffsOnboarder->waitForUnit("batman.service");

    $ffsOnboarder->waitUntilSucceeds("batctl -m batman interface");
    $ffsOnboarder->fail("batctl interface");
  '';
  

})
