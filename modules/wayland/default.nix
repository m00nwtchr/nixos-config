{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ../autologin.nix
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Bruh
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/graphical-desktop.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/wayland/wayland-session.nix
  services.xserver.desktopManager.runXdgAutostartIfNone = lib.mkForce false;
  services.graphical-desktop.enable = lib.mkForce false;

  systemd.defaultUnit = "graphical.target";

  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts-color-emoji
    unifont
  ];

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "adwaita-dark";
  };

  xdg = {
    autostart.enable = true;
    menus.enable = true;
    mime.enable = true;
    icons.enable = true;

    portal = {
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };

  programs.ssh = {
    enableAskPassword = true;
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
