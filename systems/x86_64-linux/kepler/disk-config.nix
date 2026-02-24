{
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.resumeDevice = "/dev/mapper/root";
  boot.kernelParams = ["resume_offset=219826038"];

  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      vault UUID=e2e5b425-b7ca-4bd0-aa69-44c4eb4eb890 /root/keyfile
    '';
  };

  disko.devices = {
    disk = {
      root = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0W550988A";
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

      vault = {
        device = "/dev/disk/by-id/wwn-0x50014ee2623a65bc";
        type = "disk";

        content = {
          type = "gpt";
          partitions = {
            vault = {
              size = "100%";
              content = {
                type = "luks";
                name = "vault";
                settings = {
                };
                initrdUnlock = false;
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@Documents" = {
                      mountpoint = "/home/m00n/Documents";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@Videos" = {
                      mountpoint = "/home/m00n/Videos";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@Games" = {
                      mountpoint = "/opt/Games";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
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
