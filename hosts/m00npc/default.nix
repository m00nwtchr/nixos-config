# https://search.nixos.org/options
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/efi/secureboot.nix
    ../../modules/system/desktop.nix
    ../../modules/nvidia.nix
    ../../modules/splash.nix
    ../../modules/wayland/sway.nix

    ../../modules/gaming.nix

    ./hardware-configuration.nix
  ];

  hardware.nvidia.open = true;

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  nixpkgs.overlays = [];

  boot.kernelParams = [
  ];
  # boot.plymouth.enable = false;

  networking.hostName = "m00npc"; # Define your hostname.
  networking.hosts = {
    "fd7a:115c:a1e0::f201:2d35" = ["m00nlit.dev" "matrix.m00nlit.dev"];
    "100.116.45.53" = ["m00nlit.dev" "matrix.m00nlit.dev"];
  };

  security.tpm2.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  # List services that you want to enable:
  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = ["/" "/home/m00n/Documents"];
    };
    beesd.filesystems.root = {
      spec = "/";
      hashTableSizeMB = 512;
    };
    beesd.filesystems.vault = {
      spec = "/home/m00n/Documents";
      hashTableSizeMB = 512;
    };

    tailscale.enable = true;

    ollama = {
      enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
