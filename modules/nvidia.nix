{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;

  hardware.nvidia = {
    modesetting.enable = true;

    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
  };

  boot.initrd.kernelModules = ["nvidia"];
  boot.extraModulePackages = [config.hardware.nvidia.package];
}
