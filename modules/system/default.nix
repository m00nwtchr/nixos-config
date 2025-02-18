{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  # Set your time zone.
  time.timeZone = lib.mkDefault "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  security.apparmor = {
    enable = true;
    enableCache = true;
  };

  networking.useNetworkd = true;
  systemd.network.enable = true;

  networking.firewall.enable = true;
  networking.nftables.enable = true;

  networking.nameservers = [
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [
      helix
      nil
      htop
      wget
      curl
      git
      neofetch
    ]
    ++ (
      if config.security.tpm2.enable
      then [pkgs.ssh-tpm-agent]
      else []
    );

  programs.zsh.enable = true;

  services.logrotate.checkConfig = false;
  services = {
    resolved = {
      enable = true;
      dnssec = "true";
      dnsovertls = "true";
      llmnr = "false";
      fallbackDns = [
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
    };

    tailscale.enable = lib.mkDefault true;

    dbus.implementation = "broker";
  };
}
