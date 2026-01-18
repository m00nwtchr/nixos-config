{
	config,
	pkgs,
	lib,
	...
}: {
	config =
		lib.mkIf config.facter.detected.isLaptop {
			powerManagement.powertop.enable = true;

			systemd.targets = {
				ac = {
					description = "AC Power Profile";
					unitConfig = {
						Conflicts = ["battery.target"];
						DefaultDependencies = false;
						# StopWhenUnneeded = true;
					};
				};
				battery = {
					description = "Battery Power Profile";
					unitConfig = {
						Conflicts = ["ac.target"];
						DefaultDependencies = false;
						# StopWhenUnneeded = true;
					};
				};
			};

			systemd.services = let
				smtCtl = "/sys/devices/system/cpu/smt/control";

				mkSmtScript = state:
					pkgs.writeShellScript "smt-${state}" ''
						set -eu
						if [ -w ${smtCtl} ]; then
							printf "%s\n" ${state} > ${smtCtl}
						fi
					'';
			in {
				smt-on = {
					description = "Enable SMT (Hyper-Threading)";
					wantedBy = ["ac.target"];
					after = ["multi-user.target"];
					unitConfig = {
						ConditionPathExists = smtCtl;
						ConditionACPower = true;
					};
					serviceConfig = {
						Type = "oneshot";
						ExecStart = mkSmtScript "on";
					};
				};

				smt-off = {
					description = "Disable SMT (Hyper-Threading)";
					wantedBy = ["battery.target"];
					after = ["multi-user.target"];
					unitConfig = {
						ConditionPathExists = smtCtl;
						# ConditionACPower = false;
					};
					serviceConfig = {
						Type = "oneshot";
						ExecStart = mkSmtScript "off";
					};
				};

				tailscaled.wantedBy = lib.mkForce [];
			};

			services.udev.extraRules = ''
				ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", \
					ENV{POWER_SUPPLY_ONLINE}=="1", ENV{SYSTEMD_WANTS}+="ac.target"

				ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", \
					ENV{POWER_SUPPLY_ONLINE}=="0", ENV{SYSTEMD_WANTS}+="battery.target"

				ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
				ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
				ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness"
				ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
			'';

			services = {
				logind.settings = {
					Login = {
						HandleLidSwitch = "suspend-then-hibernate";
						HandleLidSwitchExternalPower = "lock";
						HandleLidSwitchDocked = "ignore";
					};
				};

				upower.enable = true;
				m00nlit.auto-ppd.enable = true;

				networkd-dispatcher = {
					enable = true;
					rules = let
						systemctl = "${pkgs.systemd}/bin/systemctl";
						systemdCat = "${pkgs.systemd}/bin/systemd-cat";
						ip = "${pkgs.iproute2}/bin/ip";

						startTailscale =
							pkgs.writeShellScript "tailscale-start-routable" ''
								set -euo pipefail
								echo "network became routable -> starting tailscaled" | ${systemdCat} -t tailscale-power
								${systemctl} start tailscaled.service
							'';

						stopTailscaleIfOffline =
							pkgs.writeShellScript "tailscale-stop-offline" ''
								set -euo pipefail

								# Debounce a bit to avoid flapping during Wi-Fi roam/suspend-resume
								sleep 2

								# Consider "online" only if we have a default route NOT via tailscale0
								if ${ip} -4 route show default | grep -vq ' dev tailscale0' || \
								   ${ip} -6 route show default | grep -vq ' dev tailscale0'
								then
									exit 0
								fi

								echo "no non-tailscale default route -> stopping tailscaled" | ${systemdCat} -t tailscale-power
								${systemctl} stop tailscaled.service
							'';
					in {
						"stop-services" = {
							onState = ["off" "degraded"];
							script = ''
								#!${pkgs.runtimeShell}
								${stopTailscaleIfOffline}
							'';
						};
						"start-services" = {
							onState = ["routable"];
							script = ''
								#!${pkgs.runtimeShell}
								${startTailscale}
							'';
						};
					};
				};

				auto-cpufreq = {
					enable = false;
					settings = {
						battery = {
							governor = "powersave";
							turbo = "never";
						};
						charger = {
							governor = "performance";
							turbo = "auto";
						};
					};
				};

				tlp = {
					# enable = lib.mkDefault true;
					enable = false;
					settings = {
						CPU_SCALING_GOVERNOR_ON_AC = "performance";
						CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

						CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
						CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

						PLATFORM_PROFILE_ON_BAT = "low-power";
						PLATFORM_PROFILE_ON_AC = "performance";

						USB_AUTOSUSPEND = 0;

						CPU_MIN_PERF_ON_AC = 0;
						CPU_MAX_PERF_ON_AC = 100;
						CPU_MIN_PERF_ON_BAT = 0;
						CPU_MAX_PERF_ON_BAT = 20;

						START_CHARGE_THRESH_BAT0 = 40;
						STOP_CHARGE_THRESH_BAT0 = 80;
					};
				};
			};
		};
}
