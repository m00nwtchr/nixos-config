{
  den,
  lib,
  config,
  inputs,
  ...
}: {
  den.aspects.system.wayland.sway = {
    includes = [den.aspects.system.wayland];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      programs.uwsm = {
        enable = true;
        waylandCompositors.sway = {
          prettyName = "Sway";
          comment = "Sway compositor";
          binPath = "/etc/profiles/per-user/m00n/bin/sway";
        };
      };

      # programs.sway = {
      #   enable = true;
      #   xwayland.enable = true;
      #   wrapperFeatures.gtk = true;
      #   extraPackages = [];
      # };

      xdg.portal = {
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-wlr
        ];

        config.common.default = "*";
        wlr.enable = true;
        wlr.settings = {
          screencast = {
            chooser_type = "dmenu";
            chooser_cmd = "${pkgs.bemenu}/bin/bemenu";
          };
        };
      };
    };

    homeManager = {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }: let
      cfg = config.wayland.windowManager.sway.config;
      mod = cfg.modifier;
    in {
      wayland.windowManager.sway = {
        enable = true;

        # UWSM manages the session.
        systemd.enable = true;
        systemd.dbusImplementation = osConfig.services.dbus.implementation;

        wrapperFeatures.gtk = true;

        # Wallust's runtime file is unavailable in the Nix build sandbox.
        checkConfig = false;

        extraConfigEarly = ''
          include "$HOME/.local/state/wallust/sway"
        '';

        config = {
          modifier = "Mod4";
          terminal = "alacritty msg create-window || swaymsg exec -- app2unit Alacritty.desktop";
          menu = "fuzzel --launch-prefix='app2unit --fuzzel-compat --' -T 'alacritty -e'";

          assigns."number 9" = [{app_id = "librewolf";}];

          gaps = {
            inner = 4;
            outer = 10;
          };

          # Border widths already default to 2.
          window.titlebar = false;
          floating.titlebar = false;

          # Preserve native Sway defaults which differ from Home Manager's.
          fonts.size = 10.0;
          focus = {
            wrapping = "yes";
            newWindow = "urgent";
          };

          seat.seat0.xcursor_theme = "Adwaita";

          output = {
            "*".bg = "$wallpaper fill";

            "'ASUSTek COMPUTER INC PA27JCV T6L\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xff\\xff'" = {
              resolution = "3840x2160";
              scale = "1.75";
              render_bit_depth = "10";
            };

            "BOE NE160QDM-NZ6 Unknown" = {
              resolution = "2560x1600";
              scale = "1.5";
              render_bit_depth = "10";
              adaptive_sync = "on";
              color_profile = "icc ${./icc/BOE_CQ_______NE160QDM_NZ6.icm}";
            };
          };

          input = {
            "*" = {
              xkb_layout = "pl";
              xkb_options = "compose:menu";
              xkb_numlock = "enabled";
            };

            "type:touchpad" = {
              dwt = "disabled";
              dwtp = "disabled";
              tap = "enabled";
              tap_button_map = "lrm";
            };
          };

          keybindings = let
            playerctl = lib.getExe pkgs.playerctl;
            wpctl = "${pkgs.wireplumber}/bin/wpctl";
            brightnessctl = lib.getExe pkgs.brightnessctl;

            screenshotScript = pkgs.writeShellScript "screenshot.sh" ''
              PICTURES="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES)/Screenshots"

              mkdir -p "$PICTURES"

              geo=$(${pkgs.slurp}/bin/slurp -w 4)
              wh=$(echo "$geo" | awk '{print $2}')

              date=$(date +%Y-%m-%d_%H:%m:%S)

              FILE="$PICTURES/$${date}_$wh.png"

              ${pkgs.grim}/bin/grim "$@" -g "$geo" "$FILE"
              ${pkgs.wl-clipboard}/bin/wl-copy -t "image/png" < "$FILE"
              ${pkgs.libnotify}/bin/notify-send --hint=string:x-dunst-stack-tag:grim -i "$FILE" "Screenshot Captured"
            '';

            mediaToggleScript = pkgs.writeShellScript "media-toggle.sh" ''
              if [ $(${pkgs.playerctl}/bin/playerctl status -p mopidy) = 'Playing' ]; then
              	${pkgs.playerctl}/bin/playerctl play-pause -p mopidy;
              else
              	${pkgs.playerctl}/bin/playerctl play-pause -p %any,mopidy;
              fi;
            '';

            clamshellStateScript = pkgs.writeShellScript "clamshell-state.sh" ''
              LAPTOP_OUTPUT="eDP-1"
              LID_STATE_FILE="/proc/acpi/button/lid/LID/state"

              read -r LS <"$LID_STATE_FILE"

              case "$LS" in
              *open) ${pkgs.sway}/bin/swaymsg output "$LAPTOP_OUTPUT" enable ;;
              *closed) ${pkgs.sway}/bin/swaymsg output "$LAPTOP_OUTPUT" disable ;;
              *)
              	echo "Could not get lid state" >&2
              	exit 1
              	;;
              esac
            '';
          in
            lib.mkOptionDefault {
              # Remove default bindings absent from the original configuration.
              "${mod}+Return" = null;
              "${mod}+s" = null;
              "${mod}+Shift+e" = null;

              "${mod}+Shift+Return" = "exec ${cfg.terminal}";
              "${mod}+Shift+c" = "kill";
              "${mod}+Shift+r" = "reload";
              "${mod}+Shift+q" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'uwsm stop'";

              "${mod}+l" = "exec loginctl lock-session";
              "--locked ${mod}+Mod5+l" = "exec systemctl suspend-then-hibernate";

              # "${mod}+Shift+v" = "exec clip-sel.sh -l 15";
              "${mod}+Shift+S" = "exec ${screenshotScript}";

              "${mod}+Tab" = "workspace back_and_forth";
              "${mod}+greater" = "move workspace to output right";
              "${mod}+less" = "move workspace to output left";
              "${mod}+t" = "layout default";

              "${mod}+Shift+F1" = "exec ${playerctl} previous";
              "${mod}+Shift+F2" = "exec ${playerctl} next";
              "${mod}+Shift+Escape" = "exec ${mediaToggleScript}";

              "XF86AudioPrev" = "exec ${playerctl} previous";
              "XF86AudioNext" = "exec ${playerctl} next";
              "XF86AudioPlay" = "exec ${mediaToggleScript}";

              "XF86AudioRaiseVolume" = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%+";
              "XF86AudioLowerVolume" = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 10%-";
              "Shift+XF86AudioRaiseVolume" = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%+";
              "Shift+XF86AudioLowerVolume" = "exec ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 1%-";
              "XF86AudioMute" = "exec ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";

              "XF86MonBrightnessUp" = "exec ${brightnessctl} set 10%+";
              "XF86MonBrightnessDown" = "exec ${brightnessctl} set 10%-";
              "Shift+XF86MonBrightnessUp" = "exec ${brightnessctl} set 1%+";
              "Shift+XF86MonBrightnessDown" = "exec ${brightnessctl} set 1%-";
            };

          bars = [
            {command = "systemctl --user reload waybar";}
          ];
        };

        extraConfig = ''
          # Keep Sway's defaults for the omitted colour arguments.
          client.focused $color2 $color2 #FFFFFF
          client.unfocused $color0 $color0 #FFFFFF

          include /etc/sway/config.d/*
          include ~/.config/sway/config.d/*.conf
        '';
      };
    };
  };
}
