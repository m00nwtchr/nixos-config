{
  pkgs,
  lib,
  config,
  ...
}:
let
  filePath = "${config.dotfiles.path}/sway/config";
  configSrc =
    if !config.dotfiles.mutable then ./config else config.lib.file.mkOutOfStoreSymlink filePath;

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
{
  xdg.configFile."sway/config".source = configSrc;
  xdg.configFile."sway/scripts/screenshot.sh".source = screenshotScript;
  xdg.configFile."sway/scripts/media-toggle.sh".source = mediaToggleScript;
  xdg.configFile."sway/scripts/lock.sh".source = lockScript;
  xdg.configFile."sway/scripts/clamshell-state.sh".source = clamshellStateScript;
}
