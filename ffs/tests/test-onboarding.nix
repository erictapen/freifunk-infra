# Dieser Test soll das Onboarding bei FFS testen. Ein Onboarder mit den
# Skripten von https://github.com/FFS-Roland/FFS-Tools fährt hoch, ein Node
# versucht sich gegen den Onboarder zu verbinden.
import <nixpkgs/nixos/tests/make-test.nix> ({ pkgs, ...}:

{
  name = "onboarding";

  nodes = {

    ffsonboarder =
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
          hostname = "ffs-testnode";
          kontaktAdresse = "mail@example.org";
          zip = "72074";
          fastd-peer-onboarder = ''
            key "6b02214cb4eab0ea90316e1ca5cb37039b4eae4665ccd291887456b7f3f7b73d";
            remote ipv4 "ffsonboarder" port 10299;
          '';
        };
      };

  };

  testScript = ''
    $ffsonboarder->start;

    $ffsonboarder->waitForUnit("fastd.service");

    # This would fail:
    # $ffsonboarder->waitForUnit("batman.service");

    $ffsonboarder->waitUntilSucceeds("${pkgs.batctl}/bin/batctl -m batman interface");
    $ffsonboarder->fail("${pkgs.batctl}/bin/batctl interface");

    $ffsNode->start;
    $ffsNode->waitForFile("/var/lib/freifunk-vpn/ffs/fastd_secret.conf");
    $ffsNode->waitForFile("/var/lib/freifunk-vpn/ffs/nodeid");
    $ffsNode->waitForFile("/var/lib/freifunk-vpn/ffs/www/cgi-bin/nodeinfo");

    # Read nodeid from Node
    my $nodeid = $ffsNode->succeed("cat /var/lib/freifunk-vpn/ffs/nodeid");

    # Make sure the fastd connection is up. As the connection itself is
    # supposed to terminate after a while, it is not easy to test it by itself,
    # so we check, wether a certain log file appears. The *_established.log
    # should only appear, if the "on verify" script exited with 0 and the
    # connection was established.
    $ffsonboarder->waitForFile("/var/freifunk/logs/vpn*_established.log");

    # Wait for the key file to appear in the git repository
    $ffsonboarder->waitForFile("/var/freifunk/peers-ffs/vpn17/peers/ffs-$nodeid");

    # Wait for the Onboarder to commit the key
    $ffsonboarder->waitUntilSucceeds("${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ log --oneline | grep 'Onboarding (NEW_NODE) of Peer .* in Segment ..'");
  '';
  

})
