{
	description = "A simple NixOS flake";

	nixConfig = {
		extra-substituters = [
			# nix community's cache server
			"https://nix-community.cachix.org"
			# "https://attic.m00nlit.dev/m00n"
		];

		extra-trusted-public-keys = [
			# nix community's cache server public key
			"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
			"m00n:kbAQdFU/e4Vec5EnGwobPlNJ98r33SMjwkuWLV/h7lo="
		];
	};

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		snowfall-lib = {
			url = "github:snowfallorg/lib";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		lanzaboote = {
			url = "github:nix-community/lanzaboote/v0.4.3";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		disko = {
			url = "github:nix-community/disko";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		disko-zfs = {
			url = "github:numtide/disko-zfs";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.disko.follows = "disko";
		};

		nixos-hardware.url = "github:NixOS/nixos-hardware/master";

		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixpak = {
			url = "github:nixpak/nixpak";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		alejandra = {
			url = "github:kamadorueda/alejandra/main";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.home-manager.follows = "home-manager";
		};
	};

	outputs = {
		self,
		flake-parts,
		nixpkgs,
		...
	} @ inputs:
		inputs.snowfall-lib.mkFlake {
			inherit inputs;
			src = ./.;

			snowfall = {
				namespace = "m00nlit";
			};

			systems.modules.nixos = with inputs; [
				disko.nixosModules.disko
				disko-zfs.nixosModules.default
				sops-nix.nixosModules.sops
			];
			homes.modules = with inputs; [
				sops-nix.homeManagerModule
			];

			systems.hosts.beacon = {
				# system = "x86_64-linux";
				# builder = args:
				# 	inputs.nixpkgs.lib.nixosSystem
				# 	((builtins.removeAttrs args ["system"])
				# 		// {
				# 			system = "x86_64-linux";
				# 			specialArgs =
				# 				args.specialArgs
				# 				// {
				# 					system = "aarch64-linux";
				# 					format = "linux";
				# 				};
				# 			modules =
				# 				args.modules
				# 				++ [
				# 					"${inputs.snowfall-lib}/modules/nixos/user/default.nix"
				# 				];
				# 		});
			};

			outputs-builder = channels: {
				packages = {
					beacon-aarch64 =
						(inputs.self.nixosConfigurations.beacon.extendModules {
								modules = [
									{
										# nixpkgs.system = channels.nixpkgs.stdenv.hostPlatform.system;
										nixpkgs.buildPlatform = channels.nixpkgs.stdenv.hostPlatform;
										nixpkgs.hostPlatform = "aarch64-linux";

										disko.imageBuilder = {
											enableBinfmt = true;
											imageFormat = "qcow2";
											pkgs = channels.nixpkgs;
											kernelPackages = channels.nixpkgs.linuxPackages_latest;
										};

										# imports = [
										# 	"${inputs.nixpkgs}/nixos/modules/virtualisation/oci-image.nix"
										# ];
									}
								];
							}).config.system.build.diskoImagesScript;
				};
			};
		};
}
