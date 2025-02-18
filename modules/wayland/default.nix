{
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ../autologin.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "adwaita-dark";
  };

  xdg.portal = {
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  services = {
    gvfs.enable = true;
    udisks2.enable = true;
    tumbler.enable = true;
  };
}
