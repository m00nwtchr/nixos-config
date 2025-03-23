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
    "162.159.200.123"
  ];

  services.chrony = {
    enable = true;
    enableNTS = true;
  };
}
