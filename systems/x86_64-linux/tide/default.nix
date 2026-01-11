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

	# boot.kernelParams = [
	# ];
	# boot.plymouth.enable = false;

	hardware.amdgpu = {
		initrd.enable = true;
		opencl.enable = true;
	};

	boot.extraModprobeConfig = ''
		blacklist sp5100_tco
	'';

	networking.hostName = "tide"; # Define your hostname.

	security.tpm2.enable = true;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		clinfo
		rocmPackages.clr.icd
		rocmPackages.rocminfo
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

		pipewire.wireplumber.extraConfig = {
			"disable-extra-mic" = {
				"monitor.alsa.rules" = [
					{
						matches = [
							{"node.name" = "alsa_input.pci-0000_c1_00.6.HiFi__Mic1__source";}
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
