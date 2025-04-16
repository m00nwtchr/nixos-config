{
	description = "A simple NixOS flake";

	nixConfig = {
		extra-substituters = [
			# nix community's cache server
			"https://nix-community.cachix.org"
		];

		extra-trusted-public-keys = [
			# nix community's cache server public key
			"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
		];
	};

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		lanzaboote = {
			url = "github:nix-community/lanzaboote/v0.4.2";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		alejandra = {
			url = "github:kamadorueda/alejandra/main";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
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

		rust-overlay = {
			url = "github:oxalica/rust-overlay";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = {
		self,
		nixpkgs,
		lanzaboote,
		alejandra,
		sops-nix,
		home-manager,
		zen-browser,
		rust-overlay,
		...
	} @ inputs: {
		nixosConfigurations = {
			m00npc =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						sops-nix.nixosModules.sops
						lanzaboote.nixosModules.lanzaboote
						home-manager.nixosModules.home-manager
						./hosts/m00npc
						({pkgs, ...}: {
								home-manager.extraSpecialArgs = {
									inherit inputs;
									inherit system;
								};
								nixpkgs.overlays = [
									(import ./overlays/lens.nix)
									(import ./overlays/safeeyes.nix)
									# (import ./packages {
									# 		inherit system;
									# 		inherit inputs;
									# 	})
									inputs.app2unit.overlays.default
									rust-overlay.overlays.default
								];
							})
					];
				};

			m00n =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/m00n
						sops-nix.nixosModules.sops
						lanzaboote.nixosModules.lanzaboote
						home-manager.nixosModules.home-manager
						({pkgs, ...}: {
								home-manager.extraSpecialArgs = {
									inherit inputs;
									inherit system;
								};
								nixpkgs.overlays = [
									(import ./overlays/lens.nix)
									(import ./overlays/safeeyes.nix)
									# (import ./packages {
									# 		inherit system;
									# 		inherit inputs;
									# 	})
									inputs.app2unit.overlays.default
									rust-overlay.overlays.default
								];
							})
					];
				};

			m00nsrv =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/m00nsrv
						sops-nix.nixosModules.sops
						lanzaboote.nixosModules.lanzaboote
						{
							# environment.systemPackages = [alejandra.defaultPackage.${system}];
						}
					];
				};
			bastion =
				nixpkgs.lib.nixosSystem rec {
					system = "aarch64-linux";
					specialArgs = {inherit inputs;};
					modules = [
						./hosts/bastion
						sops-nix.nixosModules.sops
						{
							# environment.systemPackages = [alejandra.defaultPackage.${system}];
						}
					];
				};
		};
	};
}
