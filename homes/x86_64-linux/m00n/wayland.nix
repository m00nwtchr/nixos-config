{
	config,
	lib,
	pkgs,
	...
}: {
	# Imports
	imports = [
		./uwsm.nix
		./autostart.nix

		./sway
		./waybar
		./dunst

		./wallust
	];

	# Packages
	home.packages = with pkgs; [
		# Clipboard & Notifications
		wl-clipboard
		usbguard-notifier

		# App Launchers
		bemenu

		# Device Controls
		brightnessctl
		playerctl

		# Screenshots
		grim
		slurp

		# Lock & Background
		swaylock-effects
		swaybg

		# Themes
		wallust
		adwaita-qt

		# Fonts
		nerd-fonts.jetbrains-mono
		meslo-lgs-nf

		hack-font # Code

		kdePackages.qtwayland
		libsForQt5.qt5.qtwayland
	];

	# Font Configuration
	fonts.fontconfig.enable = true;

	# GNOME DConf Settings
	dconf = {
		enable = true;
		settings = {
			"org/gnome/desktop/interface" = {
				color-scheme = "prefer-dark";
			};
		};
	};

	# GTK Configuration
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
		gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
		gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
		gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
	};

	# Qt Configuration
	qt = {
		enable = true;
		platformTheme.name = "qt6ct";
		style.name = "Adwaita-Dark";
	};

	# Alacritty Terminal
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

	programs.eww = {
		enable = true;
		enableZshIntegration = true;
	};

	# Sway Idle Services
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
			lockScript =
				pkgs.writeShellScript "lock.sh" ''
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

	# Systemd User Services
	systemd.user = {
		targets.tray.Unit.Requires = ["waybar.service"];

		services.keepassxc = {
			Unit = {
				Description = "KeePassXC";
				PartOf = ["graphical-session.target"];
				Requires = ["tray.target"];
				After = [
					"graphical-session.target"
					"tray.target"
				];
			};
			Service = {
				Type = "exec";
				ExitType = "cgroup";
				ExecStart = ":${pkgs.keepassxc}/bin/keepassxc";
				Restart = "no";
				TimeoutStopSec = "5s";
				Slice = "app-graphical.slice";
			};
			Install.WantedBy = ["graphical-session.target"];
		};

		# services.wluma = {
		# 	Unit = {
		# 		Description = "Adjusting screen brightness based on screen contents and amount of ambient light";
		# 		After = "graphical-session.target";
		# 		PartOf = "graphical-session.target";
		# 	};
		# 	Service = {
		# 		ExecStart = "${pkgs.wluma}/bin/wluma";
		# 		Slice = "background-graphical.slice";
		# 		Restart = "always";
		# 		PrivateNetwork = true;
		# 		PrivateMounts = false;
		# 		NoNewPrivileges = true;
		# 		PrivateTmp = true;
		# 		ProtectSystem = "strict";
		# 		ProtectKernelTunables = true;
		# 		ProtectKernelModules = true;
		# 		ProtectControlGroups = true;
		# 		MemoryDenyWriteExecute = true;
		# 		RestrictSUIDSGID = true;
		# 		LockPersonality = true;
		# 	};
		# 	Install.WantedBy = ["graphical-session.target"];
		# };
	};

	# Miscellaneous Services
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
