# Dieser Test soll das Onboarding bei FFS testen. Ein Onboarder mit den
# Skripten von https://github.com/FFS-Roland/FFS-Tools fährt hoch, ein Node
# versucht sich gegen den Onboarder zu verbinden.
import <nixpkgs/nixos/tests/make-test.nix> ({ pkgs, ...}:

{
  name = "onboarding";

  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ erictapen ];
  };

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
      };

  };

  testScript = ''
    $ffsOnboarder->start;

    $ffsOnboarder->waitForUnit("fastd.service");
  '';
  
    #$ffsOnboarder->waitForUnit("batman.service");
})
