with import <nixpkgs> {};

{

  # This is far from working, but should build an image
  "futro-S550" = import <nixpkgs/nixos/lib/make-disk-image.nix> {
    name = "futro-S550-freifunk-gateway";
    inherit pkgs;
    inherit (pkgs) lib;
    config = (import <nixpkgs/nixos/lib/eval-config.nix> {
      modules = [ 
        # This is where my config lives
        ./images/futro-s550/configuration.nix 
      ];
      # Cross building fails atm...
      # system = "i686-linux";
    }).config;
    # Can we bring this down to << 1024?
    diskSize = 940;
    installBootLoader = false;
  };

}
