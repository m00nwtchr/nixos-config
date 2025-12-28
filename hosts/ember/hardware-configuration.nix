{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.initrd.availableKernelModules = [
    "asus_wmi"
  ];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
    ];
  };

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/7790403a-8bbc-4cbd-9bf6-252716a9be06";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [
      "x-initrd.attach"
      # "tpm2-measure-pcr=yes" # Causes an issue
    ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/522B-7F0C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
      "umask=0077"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
    ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@snapshots"
      "compress=zstd"
    ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 6 * 1024;
    }
  ];
}
