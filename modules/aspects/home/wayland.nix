# Port of homes/x86_64-linux/m00n/wayland.nix — wl-clipboard,
# bemenu, grim, slurp, swaylock-effects, wallust, fonts,
# alacritty, fuzzel, eww, swayidle, gammastep, cliphist, mpris.
# Imports the sway/waybar/wallust/dunst sub-aspects (defined in
# the home dir) and the bin/uwsm-game.sh script.
{ pkgs, ... }: {
  den.aspects.home.wayland = {
    homeManager = {pkgs, config, ...}: {
      home.packages = with pkgs; [
        wl-clipboard
        usbguard-notifier

        bemenu

        brightnessctl
        playerctl

        grim
        slurp

        swaylock-effects
        swaybg

        wallust
        adwaita-qt

        nerd-fonts.jetbrains-mono
        meslo-lgs-nf

        hack-font

        kdePackages.qtwayland
        # libsForQt5.qt5.qtwayland  # removed in current nixpkgs
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
          package = pkgs.papirus-icon-theme.override {color = "red";};
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        gtk4.theme = config.gtk.theme;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
        gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
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

      programs.eww.enable = true;

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
        events = let
          lockScript = pkgs.writeShellScript "lock.sh" ''
            source "${config.xdg.stateHome}/wallust/colors.sh"

            exec ${pkgs.swaylock-effects}/bin/swaylock --indicator-radius 160 \
            	--indicator-thickness 20 \
            	--inside-color 00000000 \
            	--inside-clear-color 00000000 \
            	--inside-ver-color 00000000 \
            	--inside-wrong-color 00000000 \
            	--key-hl-color "$color1" \
            	--bs-hl-color "$color2" \
            	--ring-color "$background" \
            	--ring-clear-color "$color2" \
            	--ring-wrong-color "$color5" \
            	--ring-ver-color "$color3" \
            	--line-uses-ring \
            	--line-color 00000000 \
            	--font 'MesloLGS NF:style=Thin,Regular 40' \
            	--text-color 00000000 \
            	--text-clear-color 00000000 \
            	--text-wrong-color 00000000 \
            	--text-ver-color 00000000 \
            	--separator-color 00000000 \
            	--effect-blur 10x10 \
            	--effect-compose "50%,48%;20%x20%;center;/usr/share/archlinux/icons/archlinux-icon-crystal-64.svg" \
            	"$@"
          '';
        in {
          before-sleep = "${pkgs.systemd}/bin/loginctl lock-session";
          lock = "${lockScript} -f -S";
        };
      };

      systemd.user.targets.tray.Unit.Requires = ["waybar.service"];

      services.gammastep = {
        enable = true;
        provider = "manual";
        latitude = 51.9;
        longitude = 15.5;
      };

      services.cliphist.enable = true;
      services.mpris-proxy.enable = true;

      home.file.".local/share/uwsm-game.sh" = {
        source = ./../../home/m00n/bin/uwsm-game.sh;
        executable = true;
      };
    };
  };
}
