{
  pkgs,
  lib,
  ...
}: {
  den.aspects.system.autologin = {
    nixos = {config, lib, ...}: {
      services.getty = {
        autologinUser = "m00n";
        autologinOnce = true;
      };
    };
  };
}
