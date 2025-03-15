{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [];

  networking.timeServers = [
    "time.cloudflare.com"
    "ntp.zeitgitter.net"
    "ptbtime1.ptb.de"
    "ntp2.glypnod.com"
  ];

  services.chrony = {
    enable = true;
    enableNTS = true;
  };
}
