{
	description = "A simple NixOS flake";

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

		home-manager = {
			url = "github:nix-community/home-manager";
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
		home-manager,
		rust-overlay,
		...
	} @ inputs: {
		nixosConfigurations = {
			m00n =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					modules = [
						lanzaboote.nixosModules.lanzaboote
						./hosts/m00n
						({pkgs, ...}: {
								nixpkgs.overlays = [
									(import ./overlays/lens.nix)
									rust-overlay.overlays.default
								];
								environment.systemPackages = [
									alejandra.defaultPackage.${system}
									# pkgs.rust-bin.stable.latest.default
								];
							})
						home-manager.nixosModules.home-manager
						{
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
							home-manager.users.m00n = import ./home;

							home-manager.backupFileExtension = "bak";
						}
					];
				};

			bastion =
				nixpkgs.lib.nixosSystem rec {
					system = "aarch64-linux";
					modules = [
						{
							environment.systemPackages = [alejandra.defaultPackage.${system}];
						}
						./hosts/bastion
						# {
						#   nixpkgs.overlays = [
						#     (self: super: {cni-plugin-cilium = super.callPackage ./pkgs/cni-plugin-cilium.nix {};})
						#   ];
						# }
					];
				};
		};
	};
}
