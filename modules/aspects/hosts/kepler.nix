# Host aspect for kepler. Wires together the aspects that make up
# kepler's NixOS configuration.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.kepler = {
    includes = [
      <boot/secureboot>
      <system/desktop>
      <system/splash>
      <system/vms>
      <system/gaming>

      den.aspects.vm
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
