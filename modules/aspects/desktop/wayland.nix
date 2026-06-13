{
  pkgs,
  lib,
  config,
  ...
}: {
  den.aspects.system.wayland = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # xdg desktop portal: disable autostart; we're on sway/uwsm
      services.xserver.desktopManager.runXdgAutostartIfNone = lib.mkForce false;
      services.graphical-desktop.enable = lib.mkForce false;

      systemd.defaultUnit = "graphical.target";

      security.pam.loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
      ];

      fonts.packages = with pkgs; [
        dejavu_fonts
        liberation_ttf

        noto-fonts

        noto-fonts-cjk-sans
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
      };

      programs.ssh = {
        enableAskPassword = true;
      };

      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
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
    };
  };
}
