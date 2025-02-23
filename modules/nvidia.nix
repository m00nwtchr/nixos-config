{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.nvidia = {
    modesetting.enable = true;

    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
  };
}
