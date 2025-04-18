{
  config,
  lib,
  pkgs,
  ...
}: {
  # Imports
  imports = [
    ./uwsm.nix
    ./autostart.nix

    ./sway
    ./waybar
    ./dunst

    ./wallust
  ];

  # Packages
  home.packages = with pkgs; [
    # Clipboard & Notifications
    wl-clipboard
    usbguard-notifier

    # App Launchers
    bemenu

    # Device Controls
    brightnessctl
    playerctl

    # Screenshots
    grim
    slurp

    # Lock & Background
    swaylock-effects
    swaybg

    # Themes & Fonts
    wallust
    adwaita-qt
    nerd-fonts.jetbrains-mono
    meslo-lgs-nf
  ];

  # Font Configuration
  fonts.fontconfig.enable = true;

  # GNOME DConf Settings
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

  # GTK Configuration
  gtk = {
    enable = true;
    theme.name = "Adwaita";
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override {color = "red";};
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };

  # Qt Configuration
  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "Adwaita-Dark";
  };

  # Alacritty Terminal
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 11;
        normal.family = "MesloLGS NF";
        normal.style = "Regular";
      };
      window.opacity = 0.8;
    };
  };

  programs.fuzzel = {
    enable = true;
    settings.main = {
      include = "${config.xdg.stateHome}/wallust/fuzzel.ini";

      font = "monospace:size=15";
      hide-before-typing = true;
    };
  };

  # Sway Idle Services
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        timeout = 400;
        command = ''${pkgs.sway}/bin/swaymsg "output * power off"'';
        resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * power on"'';
      }
      {
        timeout = 800;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        event = "lock";
        command = "/home/m00n/.config/sway/scripts/lock.sh -f -S";
      }
    ];
  };

  # Systemd User Services
  systemd.user = {
    targets.tray.Unit.Requires = ["waybar.service"];

    services.keepassxc = {
      Unit = {
        Description = "KeePassXC";
        PartOf = ["graphical-session.target"];
        Requires = ["tray.target"];
        After = ["graphical-session.target" "tray.target"];
      };
      Service = {
        Type = "exec";
        ExitType = "cgroup";
        ExecStart = ":${pkgs.keepassxc}/bin/keepassxc";
        Restart = "no";
        TimeoutStopSec = "5s";
        Slice = "app-graphical.slice";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    services.wluma = {
      Unit = {
        Description = "Adjusting screen brightness based on screen contents and amount of ambient light";
        After = "graphical-session.target";
        PartOf = "graphical-session.target";
      };
      Service = {
        ExecStart = "${pkgs.wluma}/bin/wluma";
        Slice = "background-graphical.slice";
        Restart = "always";
        PrivateNetwork = true;
        PrivateMounts = false;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        MemoryDenyWriteExecute = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };

  # Miscellaneous Services
  services = {
    gammastep = {
      enable = true;
      provider = "manual";
      latitude = 51.9;
      longitude = 15.5;
    };
    cliphist.enable = true;
    mpris-proxy.enable = true;
  };
}
