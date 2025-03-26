{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [];

  networking.timeServers = [
    "time.cloudflare.net"
    "ntp.zeitgitter.net"
    "ptbtime1.ptb.de"
    "ntp2.glypnod.com"
  ];

  services.chrony = {
    enable = true;
    enableNTS = true;
    initstepslew.enabled = false;
    extraConfig = ''
      server 162.159.200.1 iburst
      server 162.159.200.123 iburst
      makestep 30 3
    '';
  };
}
