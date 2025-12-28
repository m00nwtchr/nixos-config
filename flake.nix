{
	description = "A simple NixOS flake";

	nixConfig = {
		extra-substituters = [
			# nix community's cache server
			"https://nix-community.cachix.org"
			"https://attic.m00nlit.dev/m00n"
		];

		extra-trusted-public-keys = [
			# nix community's cache server public key
			"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
			"m00n:kbAQdFU/e4Vec5EnGwobPlNJ98r33SMjwkuWLV/h7lo="
		];
	};

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		lanzaboote = {
			url = "github:nix-community/lanzaboote/v0.4.3";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
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
		app2unit = {
			url = "./packages/app2unit";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = {
		self,
		nixpkgs,
		lanzaboote,
		nixos-facter-modules,
		sops-nix,
		home-manager,
		...
	} @ inputs: {
		nixosConfigurations = {
			kepler =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/kepler
						nixos-facter-modules.nixosModules.facter
						sops-nix.nixosModules.sops
						lanzaboote.nixosModules.lanzaboote
						home-manager.nixosModules.home-manager
						({pkgs, ...}: {
								home-manager.extraSpecialArgs = {
									inherit inputs;
									inherit system;
								};
							})
					];
				};

			# m00n =
			# 	nixpkgs.lib.nixosSystem rec {
			# 		system = "x86_64-linux";
			# 		specialArgs = {inherit inputs;};
			# 		modules = [
			# 			./hosts/m00n
			# 			nixos-facter-modules.nixosModules.facter
			# 			sops-nix.nixosModules.sops
			# 			lanzaboote.nixosModules.lanzaboote
			# 			home-manager.nixosModules.home-manager
			# 			({pkgs, ...}: {
			# 					home-manager.extraSpecialArgs = {
			# 						inherit inputs;
			# 						inherit system;
			# 					};
			# 				})
			# 		];
			# 	};

			ganymede =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/ganymede
						nixos-facter-modules.nixosModules.facter
						sops-nix.nixosModules.sops
						lanzaboote.nixosModules.lanzaboote
					];
				};
			beacon =
				nixpkgs.lib.nixosSystem rec {
					system = "aarch64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/beacon
						nixos-facter-modules.nixosModules.facter
						sops-nix.nixosModules.sops
					];
				};
		};
	};
}
