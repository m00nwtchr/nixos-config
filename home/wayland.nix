{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./uwsm.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    dunst

    bemenu
    fuzzel

    brightnessctl
    playerctl

    grim
    slurp

    swaylock-effects
    swaybg

    wallust
    usbguard-notifier
    safeeyes

    adwaita-qt

    ffmpegthumbnailer

    nerd-fonts.jetbrains-mono
    meslo-lgs-nf
  ];

  fonts.fontconfig.enable = true;

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

  gtk = {
    enable = true;
    theme.name = "Adwaita";
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override {
        color = "red";
      };
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };
  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "Adwaita-Dark";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 11;
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
      };

      window.opacity = 0.8;
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

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

  systemd.user.targets.tray.Unit = {
    Requires = ["waybar.service"];
  };

  xdg.configFile."systemd/user/app-io.github.slgobinath.SafeEyes@autostart.service.d/override.conf".text = ''
    [Unit]
    Requires=tray.target
    After=tray.target
  '';

  systemd.user.services.keepassxc = {
    Unit = {
      Description = "KeePassXC";
      PartOf = ["graphical-session.target"];
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
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  systemd.user.services.wluma = {
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
