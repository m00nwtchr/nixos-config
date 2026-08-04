# Port of legacy/modules/chrony.nix — chrony with NTS enabled and
# a makestep 30 3 directive. Used by server hosts (ganymede); not
# active on desktop hosts (which use systemd-timesyncd).
{
  __findFile ? __findFile,
  config,
  lib,
  ...
}: {
  den.aspects.system.chrony = {
    nixos = {...}: {
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
          makestep 30 3
        '';
      };
    };
  };
}
