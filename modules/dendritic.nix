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
      _module.args.mv = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform};
    };

    provides.to-users.homeManager = {
      user,
      osConfig,
      ...
    }: {
      _module.args.mv = osConfig._module.args.mv;
    };
  };
  den.default.includes = [den.aspects.stable];

  flake-file.inputs = {
    multiverse.url = "github:fzakaria/nixpkgs-multiverse";

    den.url = "github:denful/den";
    flake-file.url = "github:vic/flake-file";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
