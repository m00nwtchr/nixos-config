{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/sda";
      # imageSize = "32G";
      type = "disk";

      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/efi";
              mountOptions = [
                "fmask=0022"
                "dmask=0022"
                "umask=0077"
                "uid=0"
                "gid=0"
              ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "noatime"
                "nodiratime"
              ];
            };
          };
        };
      };
    };
  };
}
