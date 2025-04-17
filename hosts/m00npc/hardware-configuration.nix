{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.blacklistedKernelModules = ["amdgpu"];

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/bc65df31-228d-4c73-9b25-b57cabf231b6";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [
      "x-initrd.attach"
      # "tpm2-measure-pcr=yes"
    ];
  };

  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      vault UUID=e2e5b425-b7ca-4bd0-aa69-44c4eb4eb890 /root/keyfile
    '';
  };

  fileSystems."/" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = ["subvol=@nixos" "compress=zstd"];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = ["subvol=@nix" "compress=zstd"];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/72B6-E111";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = [
      "subvol=@snapshots"
      "compress=zstd"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/root";
    fsType = "btrfs";
    options = ["subvol=@home" "compress=zstd"];
  };

  fileSystems."/home/m00n/Documents" = {
    device = "/dev/mapper/vault";
    fsType = "btrfs";
    options = ["subvol=@Documents" "compress=zstd"];
  };

  fileSystems."/opt/Games" = {
    device = "/dev/mapper/vault";
    fsType = "btrfs";
    options = ["subvol=@Games" "compress=zstd"];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
}
