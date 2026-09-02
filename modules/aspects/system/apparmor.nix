{
  den,
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  den.aspects.apparmor = {
    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      security.apparmor = {
        enable = true;
        enableCache = true;
      };
    };
  };
}
