{
  config,
  lib,
  pkgs,
  ...
}: let
  uwsm-shell = pkgs.writeShellScriptBin "uwsm-shell" ''
    exec ${pkgs.uwsm}/bin/uwsm-app -- $(getent passwd $USER | cut -d: -f7)
  '';
in {
  home.packages = with pkgs; [
    wl-clipboard
    dunst
    alacritty

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
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override {
        color = "red";
      };
    };
    theme.name = "Adwaita";
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
      terminal.shell = "${uwsm-shell}/bin/uwsm-shell";
    };
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
  systemd.user.services.swayidle = {
    Service = {
      Type = lib.mkForce "exec";
      Slice = "background-graphical.slice"; # Assign to UWSM slice
    };
    Unit = {
      After = lib.mkForce ["graphical-session.target"];
      PartOf = lib.mkForce [];
    };
  };
  # systemd.user.services."swaybg@" = {
  # 	Unit = {
  # 		Description = "Sway wallpaper";
  # 		Documentation = "man:swaybg";
  # 		After = "graphical-session.target";
  # 	};
  # 	Service = {
  # 		Type = "exec";
  # 		ExecStart = "${pkgs.swaybg}/bin/swaybg";
  # 		Restart = "always";
  # 		Slice = "background-graphical.slice"; # Assign to UWSM slice
  # 	};
  # 	Install = {
  # 		WantedBy = ["graphical-session.target"];
  # 	};
  # };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };
  systemd.user.services.waybar = {
    Service = {
      Type = lib.mkForce "exec";
      Slice = "app-graphical.slice"; # Assign to UWSM slice
    };
    Unit = {
      After = lib.mkForce "graphical-session.target";
      PartOf = lib.mkForce [];
    };
  };

  services.cliphist = {
    enable = true;
  };
  systemd.user.services.cliphist = {
    Service = {
      Slice = "background-graphical.slice"; # Assign to UWSM slice
    };
    Unit = {
      After = lib.mkForce "graphical-session.target";
      PartOf = lib.mkForce [];
    };
  };

  services.mpris-proxy.enable = true;
}
