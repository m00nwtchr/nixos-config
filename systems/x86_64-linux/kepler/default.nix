# https://search.nixos.org/options
{
	config,
	lib,
	pkgs,
	inputs,
	...
}: {
	imports = [
		"${inputs.self}/legacy/modules/efi/secureboot.nix"
		"${inputs.self}/legacy/modules/system/desktop.nix"
		"${inputs.self}/legacy/modules/splash.nix"
		"${inputs.self}/legacy/modules/wayland/sway.nix"

		"${inputs.self}/legacy/modules/gaming.nix"
		"${inputs.self}/legacy/modules/vms.nix"

		./hardware-configuration.nix
	];

	hardware.nvidia.open = true;

	nixpkgs.overlays = [];

	boot.kernelParams = [
	];
	# boot.plymouth.enable = false;

	networking.hosts = {
		# "fd7a:115c:a1e0::f201:2d35" = ["m00nlit.dev" "matrix.m00nlit.dev"];
		# "100.116.45.53" = ["m00nlit.dev" "matrix.m00nlit.dev"];
		"fd12:3456:789a:0:5054:ff:fef3:d848" = ["virt" "virt.m00nlit.internal"];
	};
	# networking.nameservers = lib.mkForce ["fd42:78a5:2c09::53"];

	networking.firewall = {
		# allowedTCPPorts = [];
		allowedUDPPorts = [1900];
	};
	services.resolved.extraConfig = "Cache=no-negative";

	services.resolved.dnsovertls = "opportunistic";

	security.tpm2.enable = true;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
	];

	# List services that you want to enable:
	services = {
		beesd.filesystems.root = {
			spec = "/";
			hashTableSizeMB = 512;
		};
		beesd.filesystems.vault = {
			spec = "/home/m00n/Documents";
			hashTableSizeMB = 512;
		};

		tailscale.enable = true;

		ollama = {
			enable = true;
			host = "[::]";
			openFirewall = true;
		};
	};

	systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "25.05"; # Did you read the comment?
}
