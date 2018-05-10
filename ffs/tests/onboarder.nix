{ config, pkgs, lib, ... }:

let
  onboarder = pkgs.stdenv.mkDerivation {
    name = "onboarder";

    src = pkgs.fetchFromGitHub {
      owner = "erictapen";
      repo = "FFS-Tools";
      rev = "72cd7c337270064476de4bf6151deb137ed6aaca";
      sha256 = "01yh5czsjfkmj7dm2mraq5xsbcafzmin0wbj3b2z10961af2yinz";
    };

    patches = [
      (import ./make-binary-paths-patch.nix { inherit pkgs; })
      ./get-rid-off-impurity.patch
      ./pipe-fastd-on-establish-log-to-stdout.patch
    ];

    pythonPath = with pkgs.python3Packages;[
      psutil
      GitPython
      dns
      shapely
    ];
    buildInputs = with pkgs.python3Packages; [
      wrapPython
    ];

    dontBuild = true;

    installPhase = ''

      mkdir -p $out/bin
      cp Onboarding/ffs-Onboarding.py $out/bin/
      cp Onboarding/vpnXXXXX-on-establish.sh $out/bin/
      cp Onboarding/vpnXXXXX-on-verify.sh $out/bin/

      mkdir -p $out/database
      cp database/.Accounts.json    $out/database/
      cp database/Region2ZIP.json   $out/database/
      cp database/ZipGrid.json      $out/database/
      cp database/ZipLocations.json $out/database/ 


      wrapPythonPrograms
    '';
  };

  fastd-config = pkgs.writeTextFile {
    name = "fastd.conf";
    text = ''
      log level debug2;

      interface "vpn10299";
      bind any:10299;
      status socket "/var/run/fastd-vpn10299.status";
      
      method "salsa2012+umac";
      method "null+salsa2012+umac";
      mtu 1340;
      
      peer limit 1;
      
      on verify    "${onboarder}/bin/vpnXXXXX-on-verify.sh";
      on establish "${onboarder}/bin/vpnXXXXX-on-establish.sh";

      # Public: 6b02214cb4eab0ea90316e1ca5cb37039b4eae4665ccd291887456b7f3f7b73d
      secret "10f058c6744c3d3f5344521367fbb74faea131ccb7f4d3eb2411a61c7c18604d";
    '';
  };

  gitolite-sec-key-file = builtins.toFile "id_rsa" ''
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEAxbwyOR9U72bk0zKzmNLEvY8+ox0nfFNHC5m5OrS+fOzoqD0D
    7QdAWXYhyOgV/VXS73B8LTxsOa7aIT72mIuFBaAOw4tdE9R+ktX5dqAEerG+932Z
    8VarAF12XmFUc4GI1vOJbfgRIVgwyqH3zfoRCr6uYhJQJiOnpnL9+AAt0myoK/he
    6QbWdo+kWhultHPXnPqpXE7e2S8UoENu37sqnVZtvjb1oXsMpPyAXdcek56XnHlI
    8LmwKvaL3HB/qgZwCavpRwnZAoXKn8A0kl63uaL2LCi9McwLF6opSRfxrDH34moU
    PH8qItwAs3aEqgoaQnlsUiECJ7NRGuW2HKjbyQIDAQABAoIBAG4oxZYbRXdGTI74
    vSOTsHWmuw+ma1wRDRCCaLYzAbiZR5iKvYgstQXiETpbSfzj9mrcsOGGuwh7yBwj
    dsBPYiFbJT59grJMfOOS/7K9vSEZqzk4KS5RyVyftRUphiH/dVvDO7ofLHP2LOCG
    0YZYHWxuBLqwVySYUoshnymt99k1IpaDkz7Vgu4srZpzHfPz6Vi1BbeUYJavBHk3
    f79vmusOn1lAbw33/wXVCrxvdHKq3saqpFrlRZrN0Onp9kC/rcIlQUL1KPdrgVxP
    fxakRrcJKKU87ZQ6mQNGmPFkWlkLtuUR+qpa5GAVOgUSWz0jrWz7DXHoDjznfcT5
    WEe9AG0CgYEA6/W1tJhdeijz/bn7Xo/qHRmV2NqW/ZUU+hSn/+Hn3tSEiWqD33DY
    +culZzJe/D+lJc6lVlntqQI2SpkqXhcsOfIumYJdr5kDvaq/6M2Up2lD+9ssJs4D
    MGguVXmfTiribuuCipK6cea5foata88GpkaK8WgJi36l7hwexDNIQccCgYEA1odl
    t8gOee3nEa1voAyUksnNMzKT7iyGVybfNTIJxgioFgMNx4YwKA2gCvmZ/m2HhjJr
    krAVWDg3Mcatz29YoGqq99sCKpmcdvzOWYKsrPi77PTdS8kQ0cgapvxF8JLcOQ/c
    DDBA9bg8Uw4URCCnNGX/3ap3C2BZ3xGolUDA9e8CgYEApEhtm3Bd3Ni4j9Y2Qm9W
    o64Vm2cNqz5p3XgWQ9zIMGesY3Rqnl4WY0y7O29hnKS/WeRXTxjLlFk67ZNYYSwn
    Ga0Zbr3KdqDFbv98IB1KO4jZ0XeWdOoIZGKUp+RG2wiWoH2OZOalsvnd+k7QXXhF
    e+0vfcZepuWlp3OipB3EWC8CgYEAoOGRSq3hDVd4Pi2O1Lwaf6qPFKINhkQlyx3/
    rmkEI1tCkp9fqg3b922gZBqjfcauJ9mQCsW6fBpMaivRFQsvr73O0WmQylnAmQsl
    xMLWtDEk3aMUgk0bK/eg5TGzUaMRPEnEf++AB8ZOlwqr8Bt8yTLlG1tHQ2TSgRNB
    Fg0lqEkCgYEAnllS/EnuxBRaEKs1Tl6tC3Tg4qlFnGwyNY1TcE9xoIZ57sXJzbil
    T4xmhq6q9ygXfws+Jdl+AvNC3qBY7Itb0hLa8Q+Npty4a/WNNlbBqsdZWP5RKDmY
    vxvNoJfVbNI7YleJFzjWus8GWBK76ryGY3VH4GvKamU1wvrhWVTvRJI=
    -----END RSA PRIVATE KEY-----
  '';

  gitolite-pub-key = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFvDI5H1TvZuTTMrOY0sS9jz6jHSd8U0cLmbk6tL587OioPQPtB0BZdiHI6BX9VdLvcHwtPGw5rtohPvaYi4UFoA7Di10T1H6S1fl2oAR6sb73fZnxVqsAXXZeYVRzgYjW84lt+BEhWDDKoffN+hEKvq5iElAmI6emcv34AC3SbKgr+F7pBtZ2j6RaG6W0c9ec+qlcTt7ZLxSgQ27fuyqdVm2+NvWhewyk/IBd1x6TnpeceUjwubAq9ovccH+qBnAJq+lHCdkChcqfwDSSXre5ovYsKL0xzAsXqilJF/GsMffiahQ8fyoi3ACzdoSqChpCeWxSIQIns1Ea5bYcqNvJ justin@maschine
  '';

  gitolite-pub-key-file = builtins.toFile "id_rsa.pub" gitolite-pub-key;

  peers-ffs-repo = pkgs.fetchFromGitHub {
    owner = "freifunk-stuttgart";
    repo = "peers-ffs";
    rev = "4b013a0c4e9a20dab004c0030b680221de566a25";
    sha256 = "1zph2ilfwabfkpjx1s5a83f1gqdinhi3ldm996s1gcdqhw4ml6b9";
  };
  
in
{

  networking.firewall = {
    # fastd
    allowedTCPPorts = [ 10299 ];
    allowedUDPPorts = [ 10299 ];
  };
 
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ batman_adv ];
    kernelModules = [ "batman_adv" ];
  };

  environment.systemPackages = with pkgs;[
    jq
    batctl
    fastd
    vim
    onboarder
    tmux
  ];

  services.gitolite = {
    enable = true;
    adminPubkey = gitolite-pub-key;
  };

  services.openssh = {
    enable = true;
  };
  # Disable interactive questions 
  programs.ssh.extraConfig = ''
    Host *
      UserKnownHostsFile /dev/null
      StrictHostKeyChecking no
  '';
 

  systemd.services = {
    "prepare-state-dirs" = {
      after = [ "sshd.service" "gitolite-init.service" "network.target" ];
      wantedBy = [ "fastd.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # for debugging
        rm -rf /root/gitolite-admin
        rm -rf /var/freifunk/peers-ffs

        mkdir -p /var/freifunk/logs/
        mkdir -p /var/freifunk/peers-ffs/

        mkdir -p /var/freifunk/database/
        cp ${builtins.toFile "Accounts.json" "{\"Git\": {\"URL\": \"gitolite@ffsonboarder:peers-ffs.git\"}}"} /var/freifunk/database/.Accounts.json
        cp ${onboarder}/database/*.json         /var/freifunk/database/

        mkdir -p /var/freifunk/blacklist/
        mkdir -p /root/.ssh
        cat ${gitolite-sec-key-file} > /root/.ssh/id_rsa
        cat ${gitolite-pub-key-file} > /root/.ssh/id_rsa.pub
        chmod 600 /root/.ssh/id_rsa

        export HOME="/root"
        ${pkgs.git}/bin/git clone gitolite@ffsonboarder:gitolite-admin.git /root/gitolite-admin
        ${pkgs.git}/bin/git config --global user.name "System Administrator"
        ${pkgs.git}/bin/git config --global user.email "root@domain.example"

        cat <<EOF >> /root/gitolite-admin/conf/gitolite.conf

        repo peers-ffs
            RW+ = gitolite-admin
        EOF
        
        ${pkgs.git}/bin/git -C /root/gitolite-admin add -A
        ${pkgs.git}/bin/git -C /root/gitolite-admin commit -m "config"
        ${pkgs.git}/bin/git -C /root/gitolite-admin push origin master

        ${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ init
        cp -r ${peers-ffs-repo}/vpn17 /var/freifunk/peers-ffs/
        chmod -R +w /var/freifunk/peers-ffs
        ${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ add -A
        ${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ commit --quiet --allow-empty -m "initial"
        
        ${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ remote add origin gitolite@ffsonboarder:peers-ffs.git
        ${pkgs.git}/bin/git -C /var/freifunk/peers-ffs/ push -u origin master
      '';
    };

    "fastd" = {
      after = [ "prepare-state-dirs.service" ];
      wantedBy = [ "batman.service" ];
      path = with pkgs;[
        git
        procps
        onboarder
      ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.fastd}/bin/fastd --config ${fastd-config}
        '';
      };
    };
 
    "batman" = {
      after = [ "fastd.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.batctl}/bin/batctl -m "batman" interface add vpn10299
      '';
    };
  };

}
