# Port of homes/x86_64-linux/m00n/sway/default.nix — installs the
# sway config (verbatim from home/m00n/sway/config), the ICC profile
# and the generated shell scripts (screenshot, media-toggle,
# clamshell-state). The sway config text itself is a 266-line plain
# Sway file copied from the source.
{ ... }: {
  den.aspects.home.sway = {
    homeManager = {pkgs, ...}: {
      xdg.configFile."sway/config".source = ../../../home/m00n/sway/config;

      xdg.configFile."sway/config.d/10-icc.conf".text = ''
        output "BOE NE160QDM-NZ6 Unknown" color_profile icc "/home/m00n/.config/sway/icc/BOE_CQ_______NE160QDM_NZ6.icm"
      '';

      xdg.configFile."sway/scripts/screenshot.sh".source = pkgs.writeShellScript "screenshot.sh" ''
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

      xdg.configFile."sway/scripts/media-toggle.sh".source = pkgs.writeShellScript "media-toggle.sh" ''
        if [ $(${pkgs.playerctl}/bin/playerctl status -p mopidy) = 'Playing' ]; then
          ${pkgs.playerctl}/bin/playerctl play-pause -p mopidy;
        else
          ${pkgs.playerctl}/bin/playerctl play-pause -p %any,mopidy;
        fi;
      '';

      xdg.configFile."sway/scripts/clamshell-state.sh".source = pkgs.writeShellScript "clamshell-state.sh" ''
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

      xdg.configFile."sway/icc/BOE_CQ_______NE160QDM_NZ6.icm".source = ../../../home/m00n/sway/icc/BOE_CQ_______NE160QDM_NZ6.icm;
    };
  };
}
