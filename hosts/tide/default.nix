# https://search.nixos.org/options
{
	config,
	lib,
	pkgs,
	inputs,
	...
}: {
	imports = [
		../../modules/efi/secureboot.nix
		../../modules/system/desktop.nix
		../../modules/splash.nix
		../../modules/wayland/sway.nix

		../../modules/gaming.nix

		./disk-config.nix
		inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
	];

	nixpkgs.config.rocmSupport = true;
	nixpkgs.overlays = [];

	# boot.kernelParams = [
	# ];
	# boot.plymouth.enable = false;

	networking.hostName = "tide"; # Define your hostname.

	security.tpm2.enable = true;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
	];

	# List services that you want to enable:
	services = {
		# beesd.filesystems.root = {
		#   spec = "/";
		#   hashTableSizeMB = 256;
		# };

		tailscale.enable = true;

		ollama = {
			enable = true;
			package = pkgs.ollama-vulkan;
			environmentVariables = {
			};
		};
	};

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "26.05"; # Did you read the comment?
}
