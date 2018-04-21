{ pkgs }:

pkgs.writeTextFile {
  name = "binary-paths.patch";
  text = with pkgs; ''
    diff --git a/Onboarding/ffs-Onboarding.py b/Onboarding/ffs-Onboarding.py
    index 3704210..1fe1d12 100755
    --- a/Onboarding/ffs-Onboarding.py
    +++ b/Onboarding/ffs-Onboarding.py
    @@ -403,9 +403,9 @@ def ActivateBatman(BatmanIF,FastdIF):
         NeighborMAC = None
     
         try:
    -        subprocess.run(['/usr/sbin/batctl','-m',BatmanIF,'if','add',FastdIF])
    -        subprocess.run(['/sbin/ip','link','set','dev',BatmanIF,'up'])
    -        BatctlResult = subprocess.run(['/usr/sbin/batctl','-m',BatmanIF,'if'], stdout=subprocess.PIPE)
    +        subprocess.run(['${batctl}/bin/batctl','-m',BatmanIF,'if','add',FastdIF])
    +        subprocess.run(['${iproute}/bin/ip','link','set','dev',BatmanIF,'up'])
    +        BatctlResult = subprocess.run(['${batctl}/bin/batctl','-m',BatmanIF,'if'], stdout=subprocess.PIPE)
         except:
             print('++ Cannot bring up',BatmanIF,'!')
         else:
    @@ -417,7 +417,7 @@ def ActivateBatman(BatmanIF,FastdIF):
                 NeighborMAC = None
     
                 try:
    -                BatctlN = subprocess.run(['/usr/sbin/batctl','-m',BatmanIF,'n'], stdout=subprocess.PIPE)
    +                BatctlN = subprocess.run(['${batctl}/bin/batctl','-m',BatmanIF,'n'], stdout=subprocess.PIPE)
                     BatctlResult = BatctlN.stdout.decode('utf-8')
                 except:
                     print('++ ERROR on running batctl n:',BatmanIF,'->',FastdIF)
    @@ -444,8 +444,8 @@ def DeactivateBatman(BatmanIF,FastdIF):
         print('... Deactivating Batman ...')
     
         try:
    -        subprocess.run(['/sbin/ip','link','set','dev',BatmanIF,'down'])
    -        subprocess.run(['/usr/sbin/batctl','-m',BatmanIF,'if','del',FastdIF])
    +        subprocess.run(['${iproute}/bin/ip','link','set','dev',BatmanIF,'down'])
    +        subprocess.run(['${batctl}/bin/batctl','-m',BatmanIF,'if','del',FastdIF])
             print('... Batman Interface',BatmanIF,'is down.')
         except:
             print('++ Cannot shut down',BatmanIF,'!')
    @@ -566,7 +566,7 @@ def GetBatmanNodeMAC(BatmanVpnMAC,BatmanIF):
         Retries           = 15
         NodeMainMAC       = None
     
    -    BatctlCmd = ('/usr/sbin/batctl -m %s tg' % (BatmanIF)).split()
    +    BatctlCmd = ('${batctl}/bin/batctl -m %s tg' % (BatmanIF)).split()
     
         while Retries > 0 and NodeMainMAC is None:
             Retries -= 1
    @@ -629,7 +629,7 @@ def getBatmanSegment(BatmanIF):
             CheckTime += 2
     
             try:
    -            BatctlGwl = subprocess.run(['/usr/sbin/batctl','-m',BatmanIF,'gwl'], stdout=subprocess.PIPE)
    +            BatctlGwl = subprocess.run(['${batctl}/bin/batctl','-m',BatmanIF,'gwl'], stdout=subprocess.PIPE)
                 gwl = BatctlGwl.stdout.decode('utf-8')
     
                 for Gateway in gwl.split('\n'):
  '';
}
