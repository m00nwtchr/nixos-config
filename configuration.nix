# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
	config,
	lib,
	pkgs,
	...
}: {
	imports = [
		# Include the results of the hardware scan.
		./hardware-configuration.nix
	];

	nixpkgs.config.allowUnfree = true;

	# Use the systemd-boot EFI boot loader.
	# boot.loader.systemd-boot.enable = true;
	boot.loader.systemd-boot = {
		configurationLimit = 10;
		consoleMode = "max";
	};
	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};
	boot.loader.efi.canTouchEfiVariables = true;

	boot.kernelPackages = pkgs.linuxPackages_zen;

	boot.kernelParams = [
		"quiet"
		"splash"
		"systemd.show_status=auto"
		"udev.log_level=3"
		"vt.global_cursor_default=0"

		"nowatchdogs"
		"nmi_watchdog=0"
		# "tsc=unstable"
	];

	boot.consoleLogLevel = 3;
	boot.initrd.verbose = false;

	boot.kernel.sysctl = {
		"kernel.printk" = "3 3 3 3";
	};

	security.apparmor = {
		enable = true;
		enableCache = true;
	};

	boot.plymouth = {
		enable = true;
		theme = "dna";

		themePackages = with pkgs; [
			(adi1090x-plymouth-themes.override {
					selected_themes = ["dna"];
				})
		];
	};

	nix.gc = {
		automatic = true;
		dates = "weekly";
		options = "--delete-older-than 1w";
	};
	nix.settings.auto-optimise-store = true;

	services.btrfs.autoScrub = {
		enable = true;
		fileSystems = ["/"];
	};
	# services.beesd.filesystems.root = {
	# 	spec = "/";
	# 	hashTableSizeMB = 512;
	# };

	networking.hostName = "m00n"; # Define your hostname.
	# Pick only one of the below networking options.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
	networking.wireless.iwd.enable = true;
	systemd.network.enable = true;
	networking.useNetworkd = true;
	# networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

	services.dbus.implementation = "broker";

	networking.nameservers = [
		"2620:fe::fe#dns.quad9.net"
		"2620:fe::9#dns.quad9.net"
		"9.9.9.9#dns.quad9.net"
		"149.112.112.112#dns.quad9.net"
	];
	services.resolved = {
		enable = true;
		dnssec = "true";
		fallbackDns = [
			"2620:fe::fe#dns.quad9.net"
			"2620:fe::9#dns.quad9.net"
			"9.9.9.9#dns.quad9.net"
			"149.112.112.112#dns.quad9.net"
		];
		dnsovertls = "true";
		llmnr = "false";
		extraConfig = ''
		  MulticastDNS=resolve
		'';
	};

	nix.settings.experimental-features = [
		"nix-command"
		"flakes"
	];

	services.getty.autologinUser = "m00n";

	# Set your time zone.
	time.timeZone = "Europe/Warsaw";

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";
	console = {
		font = "Lat2-Terminus16";
		keyMap = "pl";
	};

	services.tlp = {
		enable = true;
		settings = {
			CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
			PLATFORM_PROFILE_ON_BAT = "low-power";
			CPU_BOOST_ON_BAT = 0;
			CPU_HWP_DYN_BOOST_ON_BAT = 0;
			AMDGPU_ABM_LEVEL_ON_BAT = 3;

			CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
			PLATFORM_PROFILE_ON_AC = "performance";

			START_CHARGE_THRESH_BAT0 = 75;
			STOP_CHARGE_THRESH_BAT0 = 80;
		};
	};

	# Enable CUPS to print documents.
	# services.printing.enable = true;

	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		pulse.enable = true;
	};

	hardware.bluetooth.enable = true;

	services.usbguard = {
		enable = true;
		dbus.enable = true;
		IPCAllowedGroups = ["wheel"];
	};

	# Enable touchpad support (enabled default in most desktopManager).
	# services.libinput.enable = true;

	environment.sessionVariables.NIXOS_OZONE_WL = "1";

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.m00n = {
		isNormalUser = true;
		extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
		shell = pkgs.zsh;
	};

	fonts.packages = with pkgs; [
		nerd-fonts.jetbrains-mono
		meslo-lgs-nf
	];

	qt = {
		enable = true;
		platformTheme = "qt5ct";
		style = "adwaita-dark";
	};

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		helix # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
		wget
		sbctl
	];

	programs.zsh.enable = true;

	programs.uwsm.enable = true;
	programs.uwsm.waylandCompositors.sway = {
		prettyName = "Sway";
		comment = "Sway compositor";
		binPath = "/run/current-system/sw/bin/sway";
	};

	programs.sway = {
		enable = true;
		xwayland.enable = false;
		extraPackages = [];
	};
	programs.waybar.enable = true;

	xdg.portal = {
		wlr.enable = true;
		extraPortals = with pkgs; [
			xdg-desktop-portal-gtk
		];
	};

	services.gvfs.enable = true;
	services.udisks2.enable = true;
	programs.thunar = {
		enable = true;
		plugins = with pkgs.xfce; [
			thunar-archive-plugin
			thunar-volman
			thunar-media-tags-plugin
		];
	};
	services.tumbler.enable = true;

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Enable the OpenSSH daemon.
	services.openssh.enable = true;

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ ... ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.
	# networking.firewall.enable = false;

	networking.nftables.enable = true;

	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
		localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
	};

	# This option defines the first version of NixOS you have installed on this particular machine,
	# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
	#
	# Most users should NEVER change this value after the initial install, for any reason,
	# even if you've upgraded your system to a new NixOS release.
	#
	# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
	# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
	# to actually do that.
	#
	# This value being lower than the current NixOS release does NOT mean your system is
	# out of date, out of support, or vulnerable.
	#
	# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
	# and migrated your data accordingly.
	#
	# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
	system.stateVersion = "24.11"; # Did you read the comment?
}
