# https://search.nixos.org/options
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/efi/secureboot.nix
    ../../modules/system/k3s.nix

    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  boot.kernelParams = [];

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  zramSwap.enable = true;

  networking.hostName = "m00nsrv"; # Define your hostname.

  networking.hosts = {
    "2a02:a313:43e4:7080::7dc5" = ["idm.m00nlit.dev" "m00nlit.dev" "m00nsrv"];
    "192.168.0.10" = ["m00nlit.dev" "m00nsrv"];
  };

  networking.firewall = {
    allowedTCPPorts = [25565 443 80];
    allowedUDPPorts = [25565 443];
  };

  services.radvd = {
    enable = true;
    config = ''
      interface enp4s0
      {
          AdvSendAdvert     on;
          MinRtrAdvInterval 30;
          MaxRtrAdvInterval 100;

          AdvManagedFlag     off;
          AdvOtherConfigFlag on;

          prefix 2a02:a313:43e4:7080::/64
          {
              AdvOnLink       on;
              AdvAutonomous   on;
              DeprecatePrefix off;
              AdvRouterAddr   on;
          };

          # Advertise the ULA prefix on-link + SLAAC
          prefix fd42:78a5:2c09::/64
          {
              AdvOnLink     on;
              AdvAutonomous on;
              AdvRouterAddr on;
          };

          # Tell clients “use me” for DNS
          RDNSS fd42:78a5:2c09::53
          {
          };
      };
    '';
  };

  systemd.network.networks."20-wired" = {
    name = "enp4s0";

    DHCP = "no";

    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "no";
      MulticastDNS = "yes";
    };

    # fd42:78a5:2c09:0::/64
    address = [
      "192.168.0.10/24"
      "2a02:a313:43e4:7080::7dc5/128"

      "192.168.0.53/24"
      "fd42:78a5:2c09::53/64"
    ];
    gateway = ["192.168.0.1"];
  };

  # services.dnsmasq = {
  #   enable = true;
  #   settings = {};
  # };

  services.resolved.enable = false;
  networking.nameservers = ["127.0.0.1" "::1"];
  services.tailscale.extraSetFlags = ["--accept-dns=false"];
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "::1"
        ];
        access-control = ["::1 allow"];

        # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;

        so-rcvbuf = "1m";

        # Custom settings
        hide-identity = true;
        hide-version = true;
        prefer-ip6 = true;

        # # General hardening
        # qname-minimisation = true;
        # serve-expired = false;

        # # Cache size
        # msg-cache-size = "32m";
        # rrset-cache-size = "64m";

        # # DNSSEC
        #val-permissive-mode = false;
        # do-not-query-localhost = false;
        # auto-trust-anchor-file = "/var/lib/unbound/root.key";
        # val-clean-additional = true;
      };

      forward-zone = [
        {
          name = ".";
          # Upstream DoT resolvers (TLS)
          # Syntax: [IP@TLS_HOSTNAME] or hostname
          # These use port 853 for DoT
          forward-addr = [
            # Quad9:
            "2620:fe::fe#dns.quad9.net"
            "2620:fe::9#dns.quad9.net"
            # Cloudflare:
            "2606:4700:4700::1111#cloudflare-dns.com"
            "2606:4700:4700::1001#cloudflare-dns.com"
          ];
          forward-tls-upstream = true;
          forward-first = false;
        }
        {
          name = "tail096cd8.ts.net.";
          forward-addr = ["100.100.100.100"];
        }
      ];
    };
  };

  # Gitea
  users.users.git = let
    giteaShell = pkgs.writeShellScriptBin "gitea-shell" ''
      exec ${pkgs.kubectl}/bin/kubectl --client-certificate=/var/lib/git/git.crt --client-key=/var/lib/git/git.key --certificate-authority=/var/lib/git/server-ca.crt -s "https://localhost:6443" -n gitea exec -i deployment/forgejo -c forgejo -- env SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND" sh "$@"
    '';
  in {
    group = "git";
    isSystemUser = true;
    home = "/var/lib/git";
    shell = "${giteaShell}/bin/gitea-shell";
  };
  users.groups.git = {};

  services.openssh.extraConfig = ''
    Match User git
      AuthorizedKeysCommandUser git
      AuthorizedKeysCommand /etc/ssh/git_authorized_keys.sh -e git -u %u -t %t -k %k
  '';

  environment.etc."ssh/git_authorized_keys.sh" = {
    text = ''
      #!/bin/sh
      exec ${pkgs.kubectl}/bin/kubectl --client-certificate=/var/lib/git/git.crt --client-key=/var/lib/git/git.key --certificate-authority=/var/lib/git/server-ca.crt -s "https://localhost:6443" -n gitea exec -i deployment/forgejo -c forgejo -- /usr/local/bin/gitea keys "$@"
    '';
    mode = "0755";
    user = "root";
    group = "root";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    tpm2-tools
    ldns
  ];

  services.sshTpmAgent.enable = lib.mkForce false;
  security.tpm2 = {
    enable = true;
    tctiEnvironment.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  services = {
    # beesd.filesystems.root = {
    #   spec = "/";
    #   hashTableSizeMB = 512;
    # };

    cockpit = {
      # enable = true;
    };

    k3s = {
      enable = lib.mkForce true;
      role = "server";
      # serverAddr = "https://m00nsrv:6443";

      node = {
        podCIDRs = [
          "2001:cafe:42::/64"
          "10.42.0.0/24"
        ];

        ips = [
          "fd7a:115c:a1e0::f201:2d35"
          "100.116.45.53"
        ];

        externalIPs = [
          "2a02:a313:43e4:7080::7dc5"
          "192.168.0.10"
        ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
