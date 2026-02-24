{
	config,
	lib,
	pkgs,
	namespace,
	...
}: let
	cfg = config.services.${namespace}.ppd-auto;

	decideScript =
		pkgs.writeShellScript "powerprofile-decide" ''
			set -euo pipefail

			if ${pkgs.systemd}/bin/systemd-ac-power; then
				sleep 5
				if ${pkgs.systemd}/bin/systemd-ac-power; then
					exit 0
				fi
			fi

			# Find first battery and read capacity
			bat_path=""
			for d in /sys/class/power_supply/*; do
				[ -d "$d" ] || continue
				if [ "$(cat "$d/type" 2>/dev/null || true)" = "Battery" ]; then
					bat_path="$d"
					break
				fi
			done

			[ -n "$bat_path" ] || exit 0
			[ -r "$bat_path/capacity" ] || exit 0

			capacity="$(cat "$bat_path/capacity")"

			if [ "$capacity" -lt "${toString cfg.thresholdPercent}" ]; then
				target="power-saver"
			else
				target="balanced"
			fi

			${pkgs.systemd}/bin/systemctl start "powerprofile-set@''${target}.service"
		'';
in {
	options.services.${namespace}.ppd-auto = {
		enable = lib.mkEnableOption "Auto-switch power-profiles-daemon profiles using AC/battery targets + udev capacity updates";

		thresholdPercent =
			lib.mkOption {
				type = lib.types.int;
				default = 60;
				description = "Below this battery percentage, switch to power-saver (on battery).";
			};

		acTarget =
			lib.mkOption {
				type = lib.types.str;
				default = "ac.target";
				description = "Systemd target that becomes active when on AC.";
			};

		batteryTarget =
			lib.mkOption {
				type = lib.types.str;
				default = "battery.target";
				description = "Systemd target that becomes active when on battery.";
			};
	};

	config =
		lib.mkIf cfg.enable {
			services.power-profiles-daemon.enable = true;

			# Template: powerprofile-set@<profile>.service
			systemd.services."powerprofile-set@" = {
				description = "Set power profile to %i";
				after = ["power-profiles-daemon.service"];
				wants = ["power-profiles-daemon.service"];

				serviceConfig = {
					Type = "oneshot";

					ExecStart = let
						script =
							pkgs.writeShellScript "powerprofile-set-instance" ''
								set -euo pipefail
								want="$1"
								cur="$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || true)"
								if [ "$cur" != "$want" ]; then
									${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$want"
								fi
							'';
					in "${script} %i";
				};
			};

			# Instance: balanced on AC
			systemd.services."powerprofile-set@balanced" = {
				overrideStrategy = "asDropin";
				wantedBy = [cfg.acTarget];
				partOf = [cfg.acTarget];
			};

			# Battery decision service (only runs on battery)
			systemd.services.powerprofile-decide-on-battery = {
				description = "Decide power profile on battery based on capacity threshold";
				wantedBy = [cfg.batteryTarget];
				partOf = [cfg.batteryTarget];
				after = ["power-profiles-daemon.service"];
				wants = ["power-profiles-daemon.service"];

				# unitConfig = {
				# 	ConditionACPower = false;
				# };

				serviceConfig = {
					Type = "oneshot";
					ExecStart = decideScript;
				};
			};

			# udev: battery updates -> kick decision service
			services.udev.extraRules = ''
				SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ENV{SYSTEMD_WANTS}+="powerprofile-decide-on-battery.service"
			'';
		};
}
