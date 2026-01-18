{
	config,
	osConfig,
	lib,
	pkgs,
	system,
	inputs,
	...
}: {
	imports = [
		./env.nix
		./wayland.nix
		./shell.nix
		./dev.nix
		./rclone.nix

		./modules/dotfiles.nix
		inputs.sops-nix.homeManagerModule
	];

	# Home Manager needs a bit of information about you and the paths it should
	# manage.
	home.username = "m00n";
	home.homeDirectory = "/home/m00n";

	# This value determines the Home Manager release that your configuration is
	# compatible with. This helps avoid breakage when a new Home Manager release
	# introduces backwards incompatible changes.
	#
	# You should not change this value, even if you update Home Manager. If you do
	# want to update the value, then make sure to first check the Home Manager
	# release notes.
	home.stateVersion = "24.11"; # Please read the comment before changing.

	dotfiles.mutable = false;

	# The home.packages option allows you to install Nix packages into your
	# environment.
	home.packages = with pkgs; [
		ungoogled-chromium
		inputs.zen-browser.packages."${system}".default

		overskride
		helvum
		pavucontrol

		yubioath-flutter
		yubikey-manager
		keepassxc

		gomuks-web
		nheko
		# cinny-desktop
		(discord.override {
				# withOpenASAR = true;
			})
		discover-overlay

		vesktop

		imv
		gimp
		file-roller
		inkscape

		gnome-calculator
		obsidian

		yt-dlp
		pwgen

		aw-qt

		age
		age-plugin-yubikey

		qbittorrent
		protontricks
		qdirstat

		calibre
		spotify

		recoll
		thunderbird
		jellyfin-desktop
		#
		lmstudio
	];

	# Home Manager is pretty good at managing dotfiles. The primary way to manage
	# plain files is through 'home.file'.
	home.file = {
		# # Building this configuration will create a copy of 'dotfiles/screenrc' in
		# # the Nix store. Activating the configuration will then make '~/.screenrc' a
		# # symlink to the Nix store copy.
		# ".screenrc".source = dotfiles/screenrc;

		# # You can also set the file content immediately.
		# ".gradle/gradle.properties".text = ''
		#   org.gradle.console=verbose
		#   org.gradle.daemon.idletimeout=3600000
		# '';
		#
		#
	};

	xdg.configFile."Yubico/u2f_keys".text = ''
		m00n:yxO+L99UucTy+hvAd5asbRx8SZRIr8SG3GI6QWtWYv5fUxzxa5D/tjZPv30Q8+75MaaE9ntMdsrJE4RxR0O1Aw==,nwYX9cckDOdOkTotQbDHQ4H8B2Zb/ug879VKUyrsaZ8pdRmGvORQgd/XFeCwMdJFtITuYkeK8XncFXWz0Rq9Xg==,es256,+presence+pin
	'';

	xdg.mimeApps = {
		enable = true;
		defaultApplicationPackages = [
			config.programs.librewolf.package
		];
	};

	programs.librewolf = {
		enable = true;

		nativeMessagingHosts = with pkgs; [
			pywalfox-native
			ff2mpv
		];
		settings = {
			"toolkit.legacyUserProfileCustomizations.stylesheets" = true;
		};
		profiles.userjs = let
			cssPath = "${pkgs.pywalfox-native}/${pkgs.python3.sitePackages}/pywalfox/assets/css";
		in {
			path = "7tpqbfqq.userjs";
			isDefault = true;
			userChrome = builtins.readFile "${cssPath}/userChrome.css";
			userContent = builtins.readFile "${cssPath}/userContent.css";
		};
	};
	# home.file.".librewolf/native-messaging-hosts" = {
	#   source = config.home.file.".mozilla/native-messaging-hosts".source;
	#   recursive = true;
	# };

	programs.mpv = {
		enable = true;
		scripts = with pkgs.mpvScripts; [
			mpris
		];

		config = {
			osc = true;
			vo = "gpu-next";
			ao = "pipewire";

			hwdec = "auto-safe";

			ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
			screenshot-template = "%F - [%P]v%#01n";
		};

		profiles = {
			hq = {
				profile = "gpu-hq";
				scale = "ewa_lanczos";
				cscale = "ewa_lanczos";
				video-sync = "display-resample";
				interpolation = true;
				#tscale="oversample";
				tscale = "sphinx";
				tscale-blur = "0.6991556596428412";
				ytdl-format = "bestvideo+bestaudio/best";
			};
		};
	};

	services = {
		easyeffects = let
			presetsPath = ../hosts/${osConfig.networking.hostName}/easyeffects;

			entries =
				if builtins.pathExists presetsPath
				then builtins.readDir presetsPath
				else {};
			presetFiles =
				lib.filterAttrs
				(name: type: type == "regular" && lib.hasSuffix ".json" name)
				entries;
			presets =
				lib.mapAttrs'
				(
					name: _: let
						key = lib.removeSuffix ".json" name;
						path = presetsPath + "/${name}";
					in
						lib.nameValuePair key (builtins.fromJSON (builtins.readFile path))
				)
				presetFiles;

			presetNames = lib.attrNames presets;
			preset =
				if builtins.length presetNames == 1
				then builtins.head presetNames
				else null;
		in {
			enable = true;
			extraPresets = presets;
			preset = lib.mkIf (preset != null) preset;
		};

		syncthing = {
			enable = true;
			guiAddress = "[::1]:8384";
			tray.enable = true;
		};

		gnome-keyring.enable = true;

		activitywatch = {
			enable = false;
			package = pkgs.aw-server-rust;

			watchers = {
				aw-watcher-window-wayland = {
					package = pkgs.aw-watcher-window-wayland;
					settings = {
						poll_time = 1;
					};
				};
			};
		};
	};
	# Let Home Manager install and manage itself.
	programs.home-manager.enable = true;
}
