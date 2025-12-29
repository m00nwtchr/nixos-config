{
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk.root = {
      device = lib.mkDefault "/dev/nvme0n1";
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
              ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "root";
              askPassword = true;
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              initrdUnlock = true;
              content = {
                type = "btrfs";
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };

                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@swap" = {
                    mountpoint = "/.swap";
                    swap.swapfile.size = "32G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
