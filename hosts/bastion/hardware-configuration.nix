{
  config,
  lib,
  pkgs,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/cloudimg-rootfs";
    fsType = "ext4";
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-label/UEFI";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
      "uid=0"
      "gid=0"
    ];
  };

  zramSwap.enable = true;
}
