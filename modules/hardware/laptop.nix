{
	config,
	pkgs,
	lib,
	...
}: {
	config =
		lib.mkIf config.facter.detected.isLaptop {
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
						HandleLidSwitch = "suspend";
						HandleLidSwitchExternalPower = "lock";
						HandleLidSwitchDocked = "ignore";
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
