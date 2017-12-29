{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ 
    # Terminal
    tmux
    bash
    screen
    tree
    vim 
    git 
    zip
    unzip
    gzip
    bzip2

    # Diagnostics
    htop
    atop
    lm_sensors
    file
    lsof
    jnettop
    bmon

    # Build tools
    gnumake

    # Network
    wget
    openssl
    nmap
    netcat
    pv
  ];


}
