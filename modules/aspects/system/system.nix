# Port of legacy/modules/system/default.nix — base NixOS config
# (nix settings, apparmor, networkd, zramSwap, nameservers, basic
# system packages, tailscale, resolved). Declared as a top-level
# `den.aspects.system` aspect; hosts that include it get the full
# base config.
{
  den,
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  den.aspects.system = {
    includes = [den.aspects.nix];

    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      boot.tmp.cleanOnBoot = true;

      time.timeZone = lib.mkDefault "Europe/Warsaw";
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

      users.mutableUsers = false;

      zramSwap = {
        enable = true;
        priority = 100;
      };

      boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
        "vm.swappiness" = 180;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.page-cluster" = 0;
      };

      environment.systemPackages = with pkgs; [
        helix
        # nil
        nh
        htop
        wget
        curl
        git
        fastfetch

        e2fsprogs

        attic-client
      ];

      programs.zsh.enable = true;

      services.logrotate.checkConfig = false;
      services = {
        resolved = {
          enable = lib.mkDefault true;
          settings.Resolve = {
            DNSSEC = "true";
            DNSOverTLS = lib.mkDefault "true";
            LLMNR = "false";
            FallbackDNS = [
              "2620:fe::fe#dns.quad9.net"
              "2620:fe::9#dns.quad9.net"
              "9.9.9.9#dns.quad9.net"
              "149.112.112.112#dns.quad9.net"
            ];
          };
        };

        tailscale = {
          enable = lib.mkDefault true;
          openFirewall = true;
        };

        dbus.implementation = "broker";
      };
    };
  };
}
