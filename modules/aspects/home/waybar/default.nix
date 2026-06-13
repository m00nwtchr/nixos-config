# Port of homes/x86_64-linux/m00n/waybar/* — waybar status bar
# config + style. Imports the source's modules/custom/layout
# sub-configs.
{
  den,
  __findFile ? __findFile,
  ...
}: {
  den.aspects.home.waybar = {
    includes = [
      <home/waybar/custom>
      <home/waybar/layout>
      <home/waybar/modules>
    ];

    homeManager = {pkgs, ...}: {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        style = ./style.css;
        settings = {
          mainBar = {
            layer = "bottom";
            position = "top";
            margin = "5 10 0";
            height = 32;
          };
        };
      };
    };
  };
}
