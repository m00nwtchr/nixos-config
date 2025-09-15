{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ../sops-nix.nix
    ../facter.nix

    # ../upg.nix
    ../hardware
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      use-xdg-base-directories = true;
      download-buffer-size = 524288000; # 500 MiB
    };

    # do garbage collection weekly to keep disk usage low
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
    optimise.automatic = true;
  };

  boot.tmp.cleanOnBoot = true;

  # Set your time zone.
  time.timeZone = lib.mkDefault "Europe/Warsaw";

  # Select internationalisation properties.
  console.keyMap = "pl";

  security.apparmor = {
    enable = true;
    enableCache = true;
  };

  systemd.network.enable = true;
  networking.useNetworkd = true;

  networking.firewall.enable = true;
  networking.nftables.enable = true;

  networking.nameservers = [
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];

  networking.hosts = lib.mkIf config.services.tailscale.enable {
    # "fd7a:115c:a1e0::f201:2d35" = ["m00nlit.dev" "jellyfin.m00nlit.dev"];
    # "100.116.45.53" = ["m00nlit.dev" "jellyfin.m00nlit.dev"];
  };

  users.mutableUsers = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    helix
    nil
    htop
    wget
    curl
    git
    neofetch
  ];

  programs.zsh.enable = true;

  services.logrotate.checkConfig = false;
  services = {
    resolved = {
      enable = lib.mkDefault true;
      dnssec = "true";
      dnsovertls = lib.mkDefault "true";
      llmnr = "false";
      fallbackDns = [
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
    };

    tailscale = {
      enable = lib.mkDefault true;
      openFirewall = true;
    };

    dbus.implementation = "broker";
  };
}
