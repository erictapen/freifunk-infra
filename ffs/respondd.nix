with import <nixpkgs>{};

stdenv.mkDerivation {
  name = "respondd";
  version = "2016-06-22";

  src = pkgs.fetchFromGitHub rec{
    owner = "erictapen";
    repo = "node-respondd";
    rev = "79ae64d297a0dba06251f2fc5988b978a207c0fe";
    sha256 = "1qck8blfixw29l9631vmi0123f8sb2yvf81087wf2jldbs7rpmrb";
  };

  buildInputs = with pkgs;[ nodejs ];

  buildPhase = ''
    patchShebangs respondd
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp respondd $out/bin/respondd
  '';
  
}
