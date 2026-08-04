{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko-zfs = {
      url = "github:numtide/disko-zfs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };
  };

  den.aspects.system.disk = {
    swap = {
      includes = [den.aspects.system.disk];
      nixos = {lib, ...}: {
        boot.resumeDevice = "/dev/mapper/root";

        disko.devices.disk.root.content.partitions.root.content.content.subvolumes."@swap" = {
          mountpoint = "/.swap";
          swap.swapfile.size = "32G";
        };
      };
    };

    zfs = {
      nixos = {lib, ...}: {
        imports = [
          inputs.disko.nixosModules.disko
          inputs.disko-zfs.nixosModules.default
        ];

        disko.enableConfig = true;
        disko.zfs.enable = true;

        # Default rpool layout — the dataset tree every zfs-root
        # host inherits. Hosts override `disko.devices.zpool.rpool`
        # to add hardware-specific pool options and add their own
        # zpools (spark, vault, …) alongside.
        disko.devices.zpool.rpool = {
          type = "zpool";
          mode = lib.mkDefault null;

          options = {
            ashift = lib.mkDefault 12;
          };

          rootFsOptions = {
            compression = lib.mkDefault "zstd";
          };

          datasets = {
            root = {
              type = "zfs_fs";
              mountpoint = "/";
              options.mountpoint = "legacy";
            };
            home = {
              type = "zfs_fs";
              options = {
                mountpoint = "/home";
                atime = "off";
                devices = "off";
                setuid = "off";
              };
            };
            nix = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                mountpoint = "legacy";
                compression = "zstd-6";
                atime = "off";
              };
            };
            var = {
              type = "zfs_fs";
              options = {
                mountpoint = "none";
                canmount = "off";
              };
            };
            "var/log" = {
              type = "zfs_fs";
              mountpoint = "/var/log";
              options = {
                mountpoint = "legacy";
                compression = "zstd-3";
                atime = "off";
                recordsize = "16K";
              };
            };
          };
        };
      };
    };

    nixos = {lib, ...}: {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko.devices = {
        disk.root = {
          device = lib.mkDefault "/dev/nvme0n1";

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
