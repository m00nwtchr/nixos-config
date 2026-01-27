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
		defaultApplicationPackages = with pkgs; [
			config.programs.librewolf.package
			imv
			papers
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
		scripts = with pkgs.mpvScripts;
		with pkgs.mpvScripts.builtins; [
			mpris
			modernz
			sponsorblock
			thumbfast
			autoload
		];

		config = {
			profile = "high-quality";
			vo = "gpu-next";

			gpu-api = "vulkan";
			fullscreen = true;
			taskbar-progress = false;
			force-seekable = true;
			keep-open = "always";

			reset-on-next-file = "pause";

			hwdec = "vulkan";
			dither-depth = 10;
			scale-antiring = 0.6;

			scale = "ewa_lanczossharp";
			dscale = "mitchell";
			cscale = "ewa_lanczossharp";

			gpu-shader-cache-dir = "~~cache/shaders";

			deband = false;
			deband-iterations = 2;
			deband-threshold = 64;
			deband-range = 17;
			deband-grain = 12;

			osd-bar = false;
			osc = false;
			border = true;
			cursor-autohide-fs-only = true;

			cursor-autohide = 300;
			osd-level = 1;
			osd-duration = 1000;
			hr-seek = true;

			osd-font = "Verdana";
			osd-font-size = 20;
			osd-color = "#FFFFFF";
			osd-border-color = "#000000";
			osd-border-size = 0.2;
			osd-blur = 0.2;

			alang = "ja,jp,jpn,en,eng";
			slang = "en,eng";

			volume = 100;
			audio-file-auto = "fuzzy";
			volume-max = 200;
			audio-pitch-correction = true;

			demuxer-mkv-subtitle-preroll = true;
			sub-fix-timing = false;
			sub-auto = "all";

			sub-font = "Netflix Sans Medium"; # Specify font to use for subtitles that do not themselves specify a particular font
			sub-font-size = 40;
			sub-color = "#FFFFFFFF";
			sub-border-color = "#FF000000";
			sub-border-size = 2.0;
			sub-shadow-offset = 0;
			sub-spacing = 0.0;

			screenshot-format = "png"; # Output format of screenshots
			screenshot-high-bit-depth = true; # Same output bitdepth as the video. Set it "no" if you want to save disc space
			screenshot-png-compression = 1; # Compression of the PNG picture (1-9).
			# Higher value means better compression, but takes more time
			screenshot-directory = "~/Pictures/mpv-screenshots"; # Output directory
			screenshot-template = "%f-%wH.%wM.%wS.%wT-#%#00n";

			# blend-subtitles = true;
			# video-sync = "display-resample";
			# interpolation = true;
			# tscale = "oversample";

			# cache = true;
			# cache-on-disk = true;
			# cache-dir = "~~cache";
			# demuxer-max-bytes = "1000MiB";
			# demuxer-readahead-secs = 300;
			# demuxer-max-back-bytes = "200MiB";
		};

		scriptOpts = {
			ytdl_hook = {
				ytdl_path = "${pkgs.yt-dlp}/bin/yt-dlp";
			};
			# modernz = {       };
		};

		profiles = {
		};
	};

	services = {
		easyeffects.enable = true;

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
