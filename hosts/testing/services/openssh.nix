{ config, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
    passwordAuthentication = false;
    listenAddresses = [ { 
      addr = "0.0.0.0"; 
      port = 8765;
    }];
  };

}
