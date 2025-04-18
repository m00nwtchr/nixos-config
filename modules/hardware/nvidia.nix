{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
    cudaSupport = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = lib.mkDefault config.hardware.graphics.enable;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
  };
  hardware.nvidia-container-toolkit.enable = config.virtualisation.containers.enable;
  environment.systemPackages = [config.hardware.nvidia.package];

  boot = {
    blacklistedKernelModules = ["nouveau"];
    initrd.kernelModules = [
      # "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    extraModulePackages = [config.hardware.nvidia.package];
    extraModprobeConfig = ''
      options nvidia NVreg_UsePageAttributeTable=1
    '';
  };

  programs.sway.extraOptions = ["--unsupported-gpu"];

  services.xserver = {
    enable = lib.mkDefault false;
    videoDrivers = ["nvidia"];
  };
}
