# Host aspect for kepler. Wires together the aspects that make up
# kepler's NixOS configuration.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.kepler.disk = {
    includes = [
      <system/disk/default>
    ];
    nixos = {lib, ...}: {
      # boot.kernelParams = ["resume_offset=219826038"];

      # environment.etc.crypttab = {
      #   mode = "0600";
      #   text = ''
      #     # <volume-name> <encrypted-device> [key-file] [options]
      #     vault UUID=e2e5b425-b7ca-4bd0-aa69-44c4eb4eb890 /root/keyfile
      #   '';
      # };

      disko.devices.disk = {
        root.content.partitions.root.content.settings.crypttabExtraOpts = ["fido2-device=auto"];

        # vault = {
        #   device = "/dev/disk/by-id/wwn-0x50014ee2623a65bc";
        #   type = "disk";
        #   content = {
        #     type = "gpt";
        #     partitions = {
        #       vault = {
        #         size = "100%";
        #         content = {
        #           type = "luks";
        #           name = "vault";
        #           settings = {
        #           };
        #           initrdUnlock = false;
        #           content = {
        #             type = "btrfs";
        #             subvolumes = {
        #               "@Documents" = {
        #                 mountpoint = "/home/m00n/Documents";
        #                 mountOptions = ["compress=zstd" "noatime"];
        #               };
        #               "@Videos" = {
        #                 mountpoint = "/home/m00n/Videos";
        #                 mountOptions = ["compress=zstd" "noatime"];
        #               };
        #               "@Games" = {
        #                 mountpoint = "/opt/Games";
        #                 mountOptions = ["compress=zstd" "noatime"];
        #               };
        #             };
        #           };
        #         };
        #       };
        #     };
        #   };
        # };
      };
    };
  };

  den.aspects.kepler = {
    includes = [
      <boot/secureboot>
      # <system/desktop>
      # <system/splash>
      # <system/vms>
      # <system/gaming>

      <system/server>
      <system/paseo-tap>
      <hardware/ssh-tpm-agent>

      # den.aspects.vm
      den.aspects.kepler.disk
    ];

    nixos = {
      pkgs,
      lib,
      ...
    }: {
      system.stateVersion = "26.11";

      # nixpkgs.config.rocmSupport = true;

      hardware.nvidia.open = true;

      boot.initrd.availableKernelModules = ["asus_wmi"];
      boot.extraModulePackages = [];

      # fileSystems."/" = {
      #   device = "/dev/mapper/root";
      #   fsType = "btrfs";
      #   options = [
      #     "subvol=@"
      #     "compress=zstd"
      #   ];
      # };

      # boot.initrd.luks.devices."root" = {
      #   device = "/dev/disk/by-uuid/7790403a-8bbc-4cbd-9bf6-252716a9be06";
      #   allowDiscards = true;
      #   bypassWorkqueues = true;
      #   crypttabExtraOpts = [
      #     "x-initrd.attach"
      #   ];
      # };

      # fileSystems."/efi" = {
      #   device = "/dev/disk/by-uuid/522B-7F0C";
      #   fsType = "vfat";
      #   options = [
      #     "fmask=0022"
      #     "dmask=0022"
      #     "umask=0077"
      #   ];
      # };

      # fileSystems."/home" = {
      #   device = "/dev/mapper/root";
      #   fsType = "btrfs";
      #   options = [
      #     "subvol=@home"
      #     "compress=zstd"
      #   ];
      # };

      # fileSystems."/nix" = {
      #   device = "/dev/mapper/root";
      #   fsType = "btrfs";
      #   options = [
      #     "subvol=@nix"
      #     "compress=zstd"
      #   ];
      # };

      # fileSystems."/.snapshots" = {
      #   device = "/dev/mapper/root";
      #   fsType = "btrfs";
      #   options = [
      #     "subvol=@snapshots"
      #     "compress=zstd"
      #   ];
      # };

      # swapDevices = [
      #   {
      #     device = "/var/lib/swapfile";
      #     size = 6 * 1024;
      #   }
      # ];

      boot.kernelParams = [
        "tsc=unstable"
        "clocksource=hpet"
      ];

      specialisation.noPlymouth.configuration = {
        boot.plymouth.enable = lib.mkForce false;
      };

      security.tpm2.enable = true;

      environment.systemPackages = with pkgs; [];

      programs.nix-ld.libraries = [];

      services.tailscale.enable = true;

      services.ollama = {
        enable = false;
        rocmOverrideGfx = "9.0.0";
        environmentVariables = {
          OLLAMA_LLM_LIBRARY = "cpu";
        };
      };
    };

    # Provides: kepler adds default packages to every user home on
    # this host.
    # provides.to-users.homeManager = {pkgs, ...}: {
    #   home.packages = with pkgs; [
    #     # rocm userspace tools
    #     clinfo
    #     rocmPackages.clr.icd
    #     rocmPackages.rocminfo
    #   ];
    # };
  };
}
