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
		nixosConfigurations = let
			mkSystem = system: name:
				nixpkgs.lib.nixosSystem {
					inherit system;
					specialArgs = {
						inherit inputs;
						inherit system;
					};
					modules = [
						./hosts/${system}/${name}
					];
				};

			onlyDirs = dir:
				nixpkgs.lib.attrNames (nixpkgs.lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir));

			systems = onlyDirs ./hosts;

			hostPairs =
				nixpkgs.lib.concatMap (
					system: let
						hostNames = onlyDirs (./hosts + "/${system}");
					in
						map (name: {
								inherit name;
								value = mkSystem system name;
							})
						hostNames
				)
				systems;
		in
			nixpkgs.lib.listToAttrs hostPairs;
	};
}
