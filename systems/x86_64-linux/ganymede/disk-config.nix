{lib, ...}: {
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Micron_7450_MTFDKBA960TFR_24334AA93946";

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
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };

      spark-0 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5002538e0996c7bc";

        content = {
          type = "zfs";
          pool = "spark";
        };
      };
      spark-1 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5002538e0996c831";

        content = {
          type = "zfs";
          pool = "spark";
        };
      };

      vault-0 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5000c500dbb1344b";

        content = {
          type = "luks";
          name = "vault-0";
          settings = {
            keyFile = "/root/keys/vault.key";
          };
          content = {
            type = "zfs";
            pool = "vault";
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";

        options = {
          ashift = 12;
          autotrim = true;
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
          relatime = true;
        };
        rootFsOptions = {
          compression = "zstd";
        };
        mountpoint = "/";

        datasets = {
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              atime = false;
              devices = false;
              setuid = false;
            };
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              compression = "zstd-6";
              atime = false;
            };
          };
          var = {
            type = "zfs_fs";
            mountpoint = "none";
            options = {
              canmount = "off";
            };
          };
          "var/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options = {
              compression = "zstd-3";
              atime = false;
              recordsize = "16K";
            };
          };
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
          };
          "var/lib/kubelet" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/kubelet";
            options = {
              atime = false;
              recordsize = "16K";
            };
          };
          "var/lib/containers" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/containers";
            options = {
              atime = false;
              recordsize = "16K";
            };
          };
        };
      };

      spark = {
        type = "zpool";
        mode = "mirror";

        options = {
          ashift = 12;
          autotrim = true;
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
        };
        mountpoint = "/spark";

        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "none";
            options = {
              canmount = "off";
              atime = false;
              compression = "zstd";
              relatime = false;
            };
          };
        };
      };

      vault = {
        type = "zpool";
        # mode = "mirror";

        options = {
          ashift = 12;
          autotrim = false;
          acltype = "posixacl";
          xattr = "sa";
        };
        mountpoint = "/vault";

        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "none";
            options = {
              canmount = "off";
              atime = false;
              compression = "zstd";
            };
          };

          "data/media" = {
            type = "zfs_fs";
            # mountpoint = "legacy";
            options = {
              recordsize = "1M";
              primarycache = "metadata";
            };
          };
        };
      };
    };
  };
}
