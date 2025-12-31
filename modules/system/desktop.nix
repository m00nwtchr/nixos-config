{
	config,
	pkgs,
	lib,
	inputs,
	system,
	username,
	...
}: {
	imports = [
		./default.nix
		# ../clamav.nix
		../podman.nix

		../home-manager.nix
		# ../greeter.nix

		inputs.home-manager.nixosModules.home-manager
		../../users/m00n.nix
	];

	home-manager.extraSpecialArgs = {
		inherit inputs;
		inherit system;
	};

	nixpkgs.config = {
		allowUnfree = true;
		permittedInsecurePackages = [
			"olm-3.2.16"
			"libsoup-2.74.3"
		];
	};
	nix.settings = {
		trusted-users = ["m00n"];
		extra-sandbox-paths = [config.programs.ccache.cacheDir];
	};

	nixpkgs.overlays = [
		(import ../../overlays/safeeyes.nix)
		(import ../../overlays/lens.nix)
		(import ../../overlays/pywalfox.nix)
		inputs.app2unit.overlays.default

		(self: super: {
				ccacheWrapper =
					super.ccacheWrapper.override {
						extraConfig = ''
							export CCACHE_COMPRESS=1
							export CCACHE_DIR="${config.programs.ccache.cacheDir}"
							export CCACHE_UMASK=007
							export CCACHE_SLOPPINESS=random_seed
							if [ ! -d "$CCACHE_DIR" ]; then
							  echo "====="
							  echo "Directory '$CCACHE_DIR' does not exist"
							  echo "Please create it with:"
							  echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
							  echo "  sudo chown root:nixbld '$CCACHE_DIR'"
							  echo "====="
							  exit 1
							fi
							if [ ! -w "$CCACHE_DIR" ]; then
							  echo "====="
							  echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
							  echo "Please verify its access permissions"
							  echo "====="
							  exit 1
							fi
						'';
					};
			})
	];

	boot = {
		kernelPackages = pkgs.linuxPackages_zen;
		kernelParams = [
			"nowatchdogs"
			"nmi_watchdog=0"
		];
		kernel.sysctl."fs.inotify.max_user_watches" = 524288;
	};

	hardware.graphics.enable = true;
	hardware.nvidia.powerManagement.enable = true;

	sops.secrets."passwords/root".neededForUsers = true;
	users.users.root.hashedPasswordFile = config.sops.secrets."passwords/root".path;

	i18n = {
		defaultLocale = "en_GB.UTF-8";
		extraLocales = [
			"en_US.UTF-8/UTF-8"
			"pl_PL.UTF-8/UTF-8"
		];
	};

	environment.systemPackages = with pkgs;
		[
			xdg-user-dirs

			papers
			libreoffice-qt6-fresh
		]
		++ (
			if config.security.tpm2.enable
			then [pkgs.tpm2-tools]
			else []
		);

	programs.ccache = {
		enable = true;
		# packageNames = ["magma"];
	};
	programs.nix-ld = {
		enable = true;
		libraries = with pkgs; [
			# from your ldd list
			glib
			nss
			nspr
			atk
			at-spi2-core
			cups
			dbus
			libdrm
			gtk3
			pango
			cairo
			gdk-pixbuf
			xorg.libX11
			xorg.libXcomposite
			xorg.libXdamage
			xorg.libXext
			xorg.libXfixes
			xorg.libXrandr
			libxkbcommon
			expat
			xorg.libxcb
			mesa
			libgbm
			alsa-lib
		];
	};
	programs.appimage = {
		enable = true;
		binfmt = true;
		package =
			pkgs.appimage-run.override {
				extraPkgs = pkgs:
					with pkgs; [
					];
			};
	};

	programs.gnupg.agent = {
		enable = true;
		pinentryPackage = pkgs.pinentry-gnome3;
		# enableSSHSupport = true;
	};
	services.dbus.packages = [pkgs.gcr];

	programs.adb.enable = true;

	security.tpm2 = {
		# enable = true;
		pkcs11.enable = true;
		tctiEnvironment.enable = true;
	};
	security.pam = {
		u2f.enable = true;
		services = {
			login.u2fAuth = true;
			sudo.u2fAuth = true;
			swaylock = {
				u2fAuth = true;
				# unixAuth = false;
			};
		};
	};
	security.rtkit.enable = true;

	virtualisation = {
		containers.enable = true;
	};

	hardware.alsa.enablePersistence = true;

	# mDNS
	networking.firewall.allowedUDPPorts = [5353];
	services = {
		logind.settings.Login = {
			HandleLidSwitch = "suspend-then-hibernate";
			HibernateDelaySec = 900;
		};

		pipewire = {
			enable = true;
			alsa.enable = true;
			pulse.enable = true;
		};

		usbguard = {
			enable = false;
			dbus.enable = true;
			IPCAllowedGroups = ["wheel"];
		};

		udev.extraRules = ''
			ACTION=="remove",\
			 SUBSYSTEM=="usb",\
			 ENV{PRODUCT}=="1050/407/571",\
			 RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
		'';

		resolved.extraConfig =
			lib.mkDefault ''
				MulticastDNS=resolve
			'';

		pcscd.enable = true;
	};
}
