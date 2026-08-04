{
  inputs,
  den,
  ...
}: {
  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})

    (inputs.den.namespace "hardware" true)
    (inputs.den.namespace "users" true)
  ];

  _module.args.__findFile = den.lib.__findFile;

  den.aspects.stable = {
    nixos = {
      host,
      pkgs,
      config,
      ...
    }: {
      _module.args.pkgsStable = import inputs.stable {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (config.nixpkgs) config;
      };
    };

    provides.to-users.homeManager = {
      user,
      osConfig,
      ...
    }: {
      _module.args.pkgsStable = osConfig._module.args.pkgsStable;
    };
  };
  den.default.includes = [den.aspects.stable];

  # Meta inputs: the framework plugin (flake-file), the den
  # framework itself, and `home-manager` (used by many home aspects,
  # so kept central). Per the co-location rule, other flake-file
  # inputs are declared at the module/aspect that uses them.
  flake-file.inputs = {
    stable.url = "github:nixos/nixpkgs/nixos-26.05";
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
  };
}
