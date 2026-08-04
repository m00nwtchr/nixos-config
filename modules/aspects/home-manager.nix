{
  config,
  pkgs,
  lib,
  ...
}: {
  den.aspects.home-manager = {
    host,
    user,
  }: {
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
