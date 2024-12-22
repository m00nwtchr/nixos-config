# /etc/nixos/flake.nix
{
	description = "flake for m00n";

	inputs = {
		nixpkgs = {
			url = "github:NixOS/nixpkgs/nixos-unstable";
		};
		lanzaboote = {
			url = "github:nix-community/lanzaboote/v0.4.1";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		alejandra = {
			url = "github:kamadorueda/alejandra";
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
		home-manager,
		alejandra,
		rust-overlay,
		...
	}: {
		nixosConfigurations = {
			m00n =
				nixpkgs.lib.nixosSystem rec {
					system = "x86_64-linux";
					modules = [
						lanzaboote.nixosModules.lanzaboote
						./configuration.nix
						({pkgs, ...}: {
								nixpkgs.overlays = [rust-overlay.overlays.default];
								environment.systemPackages = [
									alejandra.defaultPackage.${system}
									pkgs.rust-bin.stable.latest.default
								];
							})
						home-manager.nixosModules.home-manager
						{
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
							home-manager.users.m00n = import ./home.nix;

							home-manager.backupFileExtension = "bak";
						}
					];
				};
		};
	};
}
