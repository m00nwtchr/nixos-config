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

      boot.kernelParams = [
        "tsc=unstable"
        "clocksource=hpet"
      ];

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
