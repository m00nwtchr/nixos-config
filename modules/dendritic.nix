{
  inputs,
  den,
  ...
}: {
  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})

    (inputs.den.namespace "hardware" true)
    (inputs.den.namespace "system" true)
    (inputs.den.namespace "users" true)
    (inputs.den.namespace "hosts" true)
    (inputs.den.namespace "home" true)
  ];

  _module.args.__findFile = den.lib.__findFile;

  # other inputs may be defined at a module using them.
  flake-file.inputs = {
    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: re-add `stable` (nixos-25.11) + a den aspect that injects
    # `_module.args.pkgsStable` into nixos/homeManager class args,
    # before un-commenting `package = pkgsStable.librewolf;` in
    # modules/aspects/users/m00n/home.nix. The source repo injects
    # it in its top-level flake.nix (see nixos-config/flake.nix).

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko-zfs = {
      url = "github:numtide/disko-zfs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # zen-browser = {
    #   url = "github:0xc000022070/zen-browser-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.home-manager.follows = "home-manager";
    # };

    alejandra = {
      url = "github:kamadorueda/alejandra/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
