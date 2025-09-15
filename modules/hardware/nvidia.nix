{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.facter.detected.nvidia {
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
    environment.systemPackages = [ config.hardware.nvidia.package ];

    boot = {
      blacklistedKernelModules = [ "nouveau" ];
      initrd.kernelModules = [
        # "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      extraModulePackages = [ config.hardware.nvidia.package ];

      kernelParams = [
        "nvidia.NVreg_UsePageAttributeTable=1"
        "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      ];
    };

    systemd.services.nvidia-suspend-then-hibernate = {
      description = "NVIDIA system suspend-then-hibernate actions";
      path = [ pkgs.kbd ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${config.hardware.nvidia.package.out}/bin/nvidia-sleep.sh \"is-suspend-then-hibernate-supported\""
          "${config.hardware.nvidia.package.out}/bin/nvidia-sleep.sh \"suspend\""
        ];
      };
      before = [ "systemd-suspend-then-hibernate.service" ];
      requiredBy = [ "systemd-suspend-then-hibernate.service" ];
    };
    systemd.services.nvidia-resume = {
      after = [
        "systemd-suspend-then-hibernate.service"
      ];
      requiredBy = [
        "systemd-suspend-then-hibernate.service"
      ];
    };

    programs.sway.extraOptions = [ "--unsupported-gpu" ];

    services.xserver = {
      enable = lib.mkDefault false;
      videoDrivers = [ "nvidia" ];
    };
  };
}
