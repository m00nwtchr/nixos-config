{
	pkgs,
	lib,
	config,
	...
}: let
	filePath = "${config.dotfiles.path}/sway/config";
	configSrc =
		if !config.dotfiles.mutable
		then ./config
		else config.lib.file.mkOutOfStoreSymlink filePath;

	screenshotScript =
		pkgs.writeShellScript "screenshot.sh" ''
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

	mediaToggleScript =
		pkgs.writeShellScript "media-toggle.sh" ''
			if [ $(${pkgs.playerctl}/bin/playerctl status -p mopidy) = 'Playing' ]; then
				${pkgs.playerctl}/bin/playerctl play-pause -p mopidy;
			else
				${pkgs.playerctl}/bin/playerctl play-pause -p %any,mopidy;
			fi;
		'';

	clamshellStateScript =
		pkgs.writeShellScript "clamshell-state.sh" ''
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
in {
	xdg.configFile."sway/config".source = configSrc;
	xdg.configFile."sway/scripts/screenshot.sh".source = screenshotScript;
	xdg.configFile."sway/scripts/media-toggle.sh".source = mediaToggleScript;
	xdg.configFile."sway/scripts/clamshell-state.sh".source = clamshellStateScript;
}
