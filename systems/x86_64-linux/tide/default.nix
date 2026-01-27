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

		./disk-config.nix
		inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
	];

	nixpkgs.config.rocmSupport = true;
	nixpkgs.overlays = [];

	# Increase the max amount of dynamically allocated VRAM
	boot.kernelParams = let
		vram = 24;
		pages = builtins.floor ((vram * 1024 * 1024) / 4.096);
	in [
		"ttm.pages_limit=${builtins.toString pages}"
		"ttm.page_pool_size=${builtins.toString pages}"
	];
	# boot.plymouth.enable = false;

	hardware.amdgpu = {
		initrd.enable = true;
		opencl.enable = true;
	};

	boot.extraModprobeConfig = ''
		blacklist sp5100_tco
	'';

	security.tpm2.enable = true;

	networking.hosts = {
		# "10.195.43.10" = ["hotspot2.intercity.pl"];
	};

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		clinfo
		rocmPackages.clr.icd
		rocmPackages.rocminfo
	];

	programs.nix-ld.libraries = with pkgs.rocmPackages; [
		hipblas
		rocblas
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
			package = pkgs.ollama-rocm;
			rocmOverrideGfx = "11.0.2";
			environmentVariables = {
			};
		};

		pipewire.wireplumber.extraConfig = {
			"disable-extra-mic" = {
				"monitor.alsa.rules" = [
					{
						matches = [
							{
								"node.nick" = "ALC285 Analog";
								"device.profile.description" = "Stereo Microphone";
							}
						];
						actions = {
							update-props = {
								"node.disabled" = true;
							};
						};
					}
				];
			};

			"set-speaker-profile" = {
				"monitor.alsa.rules" = [
					{
						matches = [
							{"device.name" = "alsa_card.pci-0000_c1_00.6";}
						];
						actions = {
							update-props = {
								"device.profile" = "HiFi (Mic1, Mic2, Speaker)";
							};
						};
					}
				];
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
