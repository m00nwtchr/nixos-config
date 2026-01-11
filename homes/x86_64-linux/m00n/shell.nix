{
	self,
	config,
	osConfig,
	lib,
	pkgs,
	...
}: {
	imports = [
		./ssh.nix
		./gpg.nix
	];

	programs.direnv = {
		enable = true;
		nix-direnv.enable = true;
		enableZshIntegration = false;
	};

	programs.zsh = {
		enable = true;
		dotDir = "${config.xdg.configHome}/zsh";
		enableCompletion = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;

		initContent = let
			p10k =
				builtins.path {
					path = ./zsh/p10k.zsh;
					name = "p10k.zsh";
				};
		in
			lib.mkMerge [
				(lib.mkBefore
					''
						(cat ${config.xdg.cacheHome}/wallust/sequences &)

						eval "$(${lib.getExe pkgs.direnv} hook zsh)"

						if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh" ]]; then
						  source "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh"
						fi
					'')

				''
					function set_window_title() {
					  print -Pn "\e]0;$TERM - %n@%m: %~\a"
					}

					autoload -Uz add-zsh-hook
					add-zsh-hook chpwd set_window_title
					set_window_title
				''

				''
					source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
					source ${p10k}
				''
			];

		completionInit = ''
			zstyle :compinstall filename "$ZDOTDIR/zshrc"
			zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
			autoload -U compinit && compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
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

	programs.atuin = {
		enable = true;
		settings = {
			auto_sync = true;
			sync_frequency = "5m";
			sync_address = "https://atuin.m00nlit.dev";
			search_mode = "fuzzy";

			key_path = osConfig.sops.secrets."atuin_key".path;
			session_path = osConfig.sops.secrets."atuin/session".path;
		};
	};

	home.packages = with pkgs; [
		zsh-powerlevel10k

		sops

		ripgrep
		jq
		yq-go

		# archives
		zip
		unzip
		xz
		p7zip
		gnutar
		zstd

		# networking tools
		ldns
		socat
		nmap

		# utils
		file
		which
		tree
		gnused
		gawk

		nix-output-monitor

		# system call monitoring
		strace
		ltrace
		lsof

		# system tools
		neofetch
		htop
		iotop # io monitoring
		iftop # network monitoring
		powertop

		sysstat
		lm_sensors # for `sensors` command
		ethtool
		pciutils # lspci
		usbutils # lsusb
	];

	# programs.helix = {
	#   enable = true;
	#   settings = {
	#     languages.language = [
	#       {
	#         name = "nix";
	#         auto-format = true;
	#         formatter.command = "${pkgs.alejandra}/bin/alejandra";
	#       }
	#     ];
	#   };
	# };
}
