# Port of homes/x86_64-linux/m00n/wallust/default.nix + templates
# — wallust theme generator. The wallust.toml + templates live in
# home/m00n/wallust/ (copied verbatim from source).
{ ... }: {
  den.aspects.home.wallust = {
    homeManager = {pkgs, config, ...}: {
      xdg.configFile."wallust/wallust.toml".source = ../../../home/m00n/wallust/wallust.toml;
      xdg.configFile."wallust/templates/colors.json".source = ../../../home/m00n/wallust/templates/colors.json;
      xdg.configFile."wallust/templates/dunst.conf".source = ../../../home/m00n/wallust/templates/dunst.conf;
      xdg.configFile."wallust/templates/helix.toml".source = ../../../home/m00n/wallust/templates/helix.toml;
      xdg.configFile."wallust/templates/state/colors.sh".source = ../../../home/m00n/wallust/templates/state/colors.sh;
      xdg.configFile."wallust/templates/state/fuzzel.ini".source = ../../../home/m00n/wallust/templates/state/fuzzel.ini;
      xdg.configFile."wallust/templates/state/sway".source = ../../../home/m00n/wallust/templates/state/sway;
      xdg.configFile."wallust/templates/state/waybar.css".source = ../../../home/m00n/wallust/templates/state/waybar.css;
    };
  };
}
