# Port of homes/x86_64-linux/m00n/waybar/* — waybar status
# bar config + style.
{ ... }: {
  den.aspects.home.waybar = {
    homeManager = {pkgs, ...}: {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        style = ../../../home/m00n/waybar/style.css;
        settings = {
          mainBar = {
            layer = "bottom";
            position = "top";
            margin = "5 10 0";
            height = 32;
            modules-left = ["sway/workspaces"];
            modules-center = ["sway/window"];
            modules-right = ["tray" "network" "battery" "wireplumber" "clock"];
          };
        };
      };
    };
  };
}
