{lib, ...}: {
  environment.etc.crypttab = {
    mode = "0600";
    text = ''
      # <volume-name> <encrypted-device> [key-file] [options]
      vault-0 UUID=45507ea6-cda1-4ca3-9c49-008b84b0f10f /root/keys/vault.key
    '';
  };

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
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
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
          initrdUnlock = false;
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
              atime = false;
              devices = false;
              setuid = false;
            };
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              compression = "zstd-6";
              atime = false;
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
              atime = false;
              recordsize = "16K";
            };
          };
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options.mountpoint = "legacy";
          };
          "var/lib/kubelet" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/kubelet";
              atime = false;
              recordsize = "16K";
            };
          };
          "var/lib/containers" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/containers";
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
          mountpoint = "/spark";
          ashift = 12;
          autotrim = true;
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
        };

        datasets = {
          data = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";

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
          mountpoint = "/vault";
          ashift = 12;
          autotrim = false;
          acltype = "posixacl";
          xattr = "sa";
        };

        datasets = {
          data = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              canmount = "off";
              atime = false;
              compression = "zstd";
            };
          };

          "data/media" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              recordsize = "1M";
              primarycache = "metadata";
            };
          };
        };
      };
    };
  };
}
