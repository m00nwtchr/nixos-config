{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = lib.mkDefault false;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
  };
  hardware.nvidia-container-toolkit.enable = config.virtualisation.containers.enable;
  environment.systemPackages = [config.hardware.nvidia.package];

  boot = {
    initrd.kernelModules = ["nvidia"];
    blacklistedKernelModules = ["nouveau"];
    extraModulePackages = [config.hardware.nvidia.package];
  };

  services.xserver = {
    enable = lib.mkDefault false;
    videoDrivers = ["nvidia"];
  };
}
