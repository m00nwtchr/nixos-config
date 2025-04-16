{
  pkgs,
  lib,
  config,
  ...
}: let
  filePath = "${config.dotfiles.path}/waybar/style.css";
  styleSrc =
    if !config.dotfiles.mutable
    then ./style.css
    else config.lib.file.mkOutOfStoreSymlink filePath;
in {
  imports = [
    ./modules.nix
    ./custom.nix
    ./layout.nix
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    style = styleSrc;
    settings.mainBar = {
      layer = "bottom";
      position = "top";

      margin = "5 10 0";
      height = 32;
      # spacing = 4;
    };
  };
}
