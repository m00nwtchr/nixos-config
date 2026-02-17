# https://search.nixos.org/options
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    "${inputs.self}/legacy/modules/efi"
    "${inputs.self}/legacy/modules/system/server.nix"

    ./disk-config.nix
  ];
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # nixpkgs.hostPlatform = "aarch64-linux";
  # nixpkgs.system = lib.mkForce null;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0"
    "nvme.shutdown_timeout=10"
    "libiscsi.debug_libiscsi_eh=1"
    "crash_kexec_post_notifiers"
  ];

  zramSwap.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      22
      443
      80
    ];
    allowedUDPPorts = [
      22
      443
    ];
  };

  security.tpm2.enable = lib.mkForce false;
  services.sshTpmAgent.enable = lib.mkForce false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [];

  services.haproxy = {
    enable = false;

    # Enable UDP support (requires HAProxy 2.0+)
    package = pkgs.haproxy; # Or use a pinned newer version if needed

    config = ''
      global
        log /dev/log local0
        log /dev/log local1 notice
        daemon

      defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

      frontend http
        bind *:80
        mode tcp
        default_backend web_backend

      frontend https
        bind *:443
        mode tcp
        default_backend websecure_backend

      # frontend https_udp
      #   bind *:443 proto udp
      #   mode udp
      #   default_backend websecure_backend_udp

      backend web_backend
        mode tcp
        server web1 127.0.0.1:30080

      backend websecure_backend
        mode tcp
        server web1 127.0.0.1:30443

      # backend websecure_backend_udp
      #   mode udp
      #   server web1 127.0.0.1:30443
    '';
  };

  services.btrfs.autoScrub.enable = false;

  virtualisation.containers.storage.settings.storage.driver = lib.mkForce "overlay";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
