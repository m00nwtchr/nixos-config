# Port of homes/x86_64-linux/m00n/sway/default.nix — installs the
# sway config + scripts + ICC profile. The actual config text
# lives in home/m00n/sway/config (a 266-line plain Sway file).
{ ... }: {
  den.aspects.home.sway = {
    homeManager = {pkgs, ...}: {
      xdg.configFile."sway/config".source = ../../../home/m00n/sway/config;
      xdg.configFile."sway/config.d/10-icc.conf".text = ''
        # Framework 16 BOE NE160QDM-NZ6 ICC profile
        output eDP-1 {
          # The actual icc profile is set via nix; here we just
          # make sure the config dir exists.
        }
      '';
      xdg.configFile."sway/scripts/screenshot.sh".source = ../../../home/m00n/sway/scripts/screenshot.sh;
      xdg.configFile."sway/scripts/media-toggle.sh".source = ../../../home/m00n/sway/scripts/media-toggle.sh;
      xdg.configFile."sway/scripts/clamshell-state.sh".source = ../../../home/m00n/sway/scripts/clamshell-state.sh;
      xdg.configFile."sway/icc/BOE_CQ_______NE160QDM_NZ6.icm".source = ../../../home/m00n/sway/icc/BOE_CQ_______NE160QDM_NZ6.icm;
    };
  };
}
