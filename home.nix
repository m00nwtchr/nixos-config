{
	config,
	lib,
	pkgs,
	...
}: {
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

	home.file.".cargo/config.toml".text = ''
	  [target.x86_64-unknown-linux-gnu]
	  linker = "clang"
	  rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
	'';

	# The home.packages option allows you to install Nix packages into your
	# environment.
	home.packages = with pkgs; [
		yadm

		yubioath-flutter
		yubikey-manager

		mold
		keepassxc

		nheko
		cinny-desktop

		ansible

		lutris
		prismlauncher

		mpv

		yt-dlp
		ffmpegthumbnailer

		dunst
		alacritty
		fuzzel
		brightnessctl
		playerctl
		grim
		bemenu
		swaylock
		swaybg

		slurp
		wluma

		gh

		tree
		powertop

		neofetch

		# archives
		zip
		xz
		unzip
		p7zip

		# utils
		ripgrep # recursively searches directories for a regex pattern
		jq # A lightweight and flexible command-line JSON processor
		yq-go # yaml processor https://github.com/mikefarah/yq
		eza # A modern replacement for ‘ls’
		fzf # A command-line fuzzy finder

		# networking tools
		mtr # A network diagnostic tool
		iperf3
		dnsutils # `dig` + `nslookup`
		ldns # replacement of `dig`, it provide the command `drill`
		aria2 # A lightweight multi-protocol & multi-source command-line download utility
		socat # replacement of openbsd-netcat
		nmap # A utility for network discovery and security auditing
		ipcalc # it is a calculator for the IPv4/v6 addresses

		usbguard-notifier
		adwaita-qt

		# misc
		cowsay
		file
		which
		tree
		gnused
		gnutar
		gawk
		zstd
		gnupg

		# nix related
		#
		# it provides the command `nom` works just like `nix`
		# with more details log output
		nix-output-monitor

		btop # replacement of htop/nmon
		iotop # io monitoring
		iftop # network monitoring

		# system call monitoring
		strace # system call monitoring
		ltrace # library call monitoring
		lsof # list open files

		# system tools
		sysstat
		lm_sensors # for `sensors` command
		ethtool
		pciutils # lspci
		usbutils # lsusb

		xdg-user-dirs

		zsh-powerlevel10k
		nil
		safeeyes
		obsidian

		vesktop

		# # Adds the 'hello' command to your environment. It prints a friendly
		# # "Hello, world!" when run.
		# pkgs.hello

		# # It is sometimes useful to fine-tune packages, for example, by applying
		# # overrides. You can do that directly here, just don't forget the
		# # parentheses. Maybe you want to install Nerd Fonts with a limited number of
		# # fonts?
		# (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

		# # You can also create simple shell scripts directly inside your
		# # configuration. For example, this adds a command 'my-hello' to your
		# # environment:
		# (pkgs.writeShellScriptBin "my-hello" ''
		#   echo "Hello, ${config.home.username}!"
		# '')
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
	};
	# Home Manager can also manage your environment variables through
	# 'home.sessionVariables'. These will be explicitly sourced when using a
	# shell provided by Home Manager. If you don't want to manage your shell
	# through Home Manager then you have to manually source 'hm-session-vars.sh'
	# located at either
	#
	#  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
	#
	# or
	#
	#  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
	#
	# or
	#
	#  /etc/profiles/per-user/m00n/etc/profile.d/hm-session-vars.sh
	#
	home.sessionVariables = {
		# EDITOR = "emacs";
	};

	programs.gpg = {
		enable = true;
		scdaemonSettings = {
			card-timeout = "5";
			disable-ccid = true;
		};
	};

	programs.librewolf = {
		enable = true;
		package =
			pkgs.librewolf.override {
				nativeMessagingHosts = with pkgs; [
					pywalfox-native
				];
			};
	};

	dconf = {
		enable = true;
		settings = {
			"org/gnome/desktop/interface" = {
				color-scheme = "prefer-dark";
			};
		};
	};

	gtk = {
		enable = true;
		iconTheme = {
			name = "Papirus-Dark";
			package =
				pkgs.papirus-icon-theme.override {
					color = "red";
				};
		};
		theme.name = "Adwaita";
		cursorTheme = {
			name = "Adwaita";
			package = pkgs.adwaita-icon-theme;
		};
		gtk4.extraConfig = {
			gtk-application-prefer-dark-theme = 1;
		};
		gtk3.extraConfig = {
			gtk-application-prefer-dark-theme = 1;
		};
	};
	programs.git = {
		enable = true;
		userName = "m00nwtchr";
		userEmail = "m00nwtchr@duck.com";
		signing = {
			key = "0x800214724BE3A82F";
			signByDefault = true;
		};
		lfs.enable = true;
		extraConfig = {
			pull.rebase = false;
			init.defaultBranch = "master";
			submodule.recurse = true;
			push.autoSetupRemote = true;
		};
	};

	services.ssh-agent.enable = true;
	programs.ssh = {
		enable = true;
		addKeysToAgent = "yes";
		compression = false;
		controlMaster = "auto";
		controlPath = "\${XDG_RUNTIME_DIR}/ssh/socket-%C";
		controlPersist = "60";
		serverAliveInterval = 15;
		serverAliveCountMax = 3;
	};

	programs.zsh = {
		enable = true;
		dotDir = ".config/zsh";
		enableCompletion = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;

		initExtraFirst = ''
		  (cat ${config.xdg.cacheHome}/wallust/sequences &)
		  if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh" ]]; then
		   source "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh"
		  fi
		'';

		completionInit = ''
		  zstyle :compinstall filename "$ZDOTDIR/zshrc"
		  zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
		  autoload -U compinit && compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
		'';

		initExtra = ''
		  source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
		  [[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"
		'';

		shellAliases = {
			ll = "ls -l";
			update = "sudo nixos-rebuild switch";
		};
		history = {
			size = 10000;
			path = "${config.xdg.stateHome}/zsh/history";
		};
	};

	# programs.helix = {
	# 	enable = true;
	# 	settings = {
	# 		languages.language = [
	# 			{
	# 				name = "nix";
	# 				auto-format = true;
	# 				formatter.command = "${pkgs.alejandra}/bin/alejandra";
	# 			}
	# 		];
	# 	};
	# };

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
		events = [
			{
				event = "before-sleep";
				command = "${pkgs.systemd}/bin/loginctl lock-session";
			}
			{
				event = "lock";
				command = "${pkgs.swaylock}/bin/swaylock -F";
			}
		];
	};
	systemd.user.services.swayidle = {
		Service = {
			Type = lib.mkForce "exec";
			Slice = "background-graphical.slice"; # Assign to UWSM slice
		};
		Unit = {
			After = "graphical-session.target";
			PartOf = lib.mkForce [];
		};
	};
	systemd.user.services."swaybg@" = {
		Unit = {
			Description = "Sway wallpaper";
			Documentation = "man:swaybg";
			After = "graphical-session.target";
		};
		Service = {
			Type = "exec";
			ExecStart = "${pkgs.swaybg}/bin/swaybg";
			Restart = "always";
			Slice = "background-graphical.slice"; # Assign to UWSM slice
		};
		Install = {
			WantedBy = ["graphical-session.target"];
		};
	};

	systemd.user.services.ssh-tpm-agent = {
		Unit = {
			ConditionEnvironment = "!SSH_AGENT_PID";
			Description = "ssh-tpm-agent service";
			Documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
			Requires = "ssh-tpm-agent.socket";
		};
		Service = {
			Environment = "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock";
			ExecStart = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent";
			PassEnvironment = "SSH_AGENT_PID";
			SuccessExitStatus = 2;
			Type = "simple";
		};
		Install = {
			Also = "ssh-agent.socket";
		};
	};
	systemd.user.sockets.ssh-tpm-agent = {
		Unit = {
			Description = "SSH TPM agent socket";
			Documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
		};
		Socket = {
			ListenStream = "%t/ssh-tpm-agent.sock";
			SocketMode = 0600;
			Service = "ssh-tpm-agent.service";
		};
		Install = {
			WantedBy = ["sockets.target"];
		};
	};

	# Let Home Manager install and manage itself.
	programs.home-manager.enable = true;
}
