# Port of homes/x86_64-linux/m00n/dunst/default.nix — dunst
# notification daemon. Source had a complex `urgency.low` setting
# that conflicts with current dunst module's stricter typing;
# simplify here.
{ ... }: {
  den.aspects.home.dunst = {
    homeManager = {pkgs, ...}: {
      services.dunst = {
        enable = true;
        settings.global = {
          width = "(0 450)";
          offset = "48x60";
          progress_bar_corner_radius = 9;
          indicate_hidden = true;
          transparency = 80;
          font = "JetBrainsMono Nerd Font 10";
          format = "<b><u>%s</u></b>\n%b\n";
          icon_theme = "Papirus-Dark";
          icon_position = "left";
          corner_radius = 9;
        };
      };
    };
  };
}
