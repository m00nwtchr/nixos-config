{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.m00n = import ../home;

  home-manager.backupFileExtension = "bak";
}
