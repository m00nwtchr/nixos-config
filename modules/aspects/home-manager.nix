{
  config,
  pkgs,
  lib,
  ...
}: {
  den.aspects.home-manager = {
    nixos = {
      config,
      lib,
      ...
    }: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
      };
    };
  };
}
