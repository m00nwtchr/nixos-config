# Host aspect for ganymede. Wires together the aspects that make
# up ganymede's NixOS configuration. Faithful port of the legacy
# nixold/systems/x86_64-linux/ganymede/default.nix.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.ganymede = {
    imports = [
      "${inputs.self}/hosts/ganymede/disk-config.nix"
    ];

    includes = [
      <boot/secureboot>
      <system/server>
      <system/zfs>
      <system/k3s>
      <hardware/ssh-tpm-agent>
    ];

    nixos = {
      config,
      lib,
      pkgs,
      pkgsStable,
      ...
    }: {
      networking.hostName = "ganymede";
      system.stateVersion = lib.mkForce "24.11";
      networking.hostId = lib.mkForce "8504e2ee";

      boot.kernelParams = [];

      fileSystems."/" = {
        device = "rpool/root";
        fsType = "zfs";
      };
      fileSystems."/nix" = {
        device = "rpool/nix";
        fsType = "zfs";
      };
      fileSystems."/var/log" = {
        device = "rpool/var/log";
        fsType = "zfs";
      };
      fileSystems."/var/lib" = {
        device = "rpool/var/lib";
        fsType = "zfs";
      };
      fileSystems."/efi" = {
        device = "/dev/disk/by-id/nvme-Micron_7450_MTFDKBA960TFR_24334AA93946-part1";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
          "umask=0077"
        ];
      };

      hardware.nvidia = {
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      };
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "nvidia-x11"
          "nvidia-kernel-modules"
        ];

      networking.firewall = {
        allowedTCPPorts = [
          25565
          443
          80
          2049
        ];
        allowedUDPPorts = [
          25565
          443
          2049
        ];
      };

      services.nfs.server.enable = true;
      services.seatd.enable = true;
      services.openiscsi = {
        enable = true;
        name = "iqn.2016-04.com.open-iscsi:bd68ae22efed";
      };

      systemd.network.links."10-lan" = {
        matchConfig.MACAddress = "9c:6b:00:08:bb:03";
        linkConfig.Name = "lan0";
      };

      services.radvd = {
        enable = true;
        config = ''
          interface lan0
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

              # Tell clients "use me" for DNS
              RDNSS fd42:78a5:2c09::53
              {
              };
          };
        '';
      };

      systemd.network.networks."20-wired" = {
        matchConfig.PermanentMACAddress = "9c:6b:00:08:bb:03";
        DHCP = "no";
        networkConfig = {
          IPv6AcceptRA = "yes";
          IPv6PrivacyExtensions = "no";
          MulticastDNS = "yes";
        };
        address = [
          "192.168.0.10/24"
          "2a02:a313:43e4:7080::7dc5/64"
          "fd42:78a5:2c09::7dc5/64"
        ];
        gateway = ["192.168.0.1"];
      };

      services.resolved.enable = false;
      networking.nameservers = ["127.0.0.1" "::1"];

      services.unbound = {
        enable = true;
        settings = {
          server = {
            interface = ["::1"];
            access-control = ["::1 allow"];

            harden-glue = true;
            harden-dnssec-stripped = true;
            use-caps-for-id = false;
            prefetch = true;
            edns-buffer-size = 1232;

            so-rcvbuf = "1m";

            hide-identity = true;
            hide-version = true;
            prefer-ip6 = true;
          };

          forward-zone = [
            {
              name = ".";
              forward-addr = [
                "2620:fe::fe#dns.quad9.net"
                "2620:fe::9#dns.quad9.net"
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

      services.openssh.ports = [2222];

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

      virtualisation.cri-o = let
        crioPackage = pkgsStable.cri-o.override {
          extraPackages =
            config.virtualisation.cri-o.extraPackages
            ++ lib.optional (config.boot.supportedFilesystems.zfs or false) config.boot.zfs.package;
        };
      in {
        package = crioPackage;
        settings = {
          crio.runtime.runtimes.nvidia = {
            runtime_path = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime";
            runtime_type = "oci";
          };
          crio.runtime.runtimes.kata = {
            runtime_path = "${pkgs.kata-runtime}/bin/containerd-shim-kata-v2";
            runtime_type = "vm";
            runtime_root = "/run/vc";
            privileged_without_host_devices = true;
          };
          crio.image.image_volumes = "mkdir";
        };
      };

      environment.etc."nvidia-container-runtime/config.toml".text = ''
        [nvidia-container-runtime]
        runtimes = ["${pkgs.crun}/bin/crun"]
      '';

      services.smartd.defaults.monitored = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../7/04) -W 4,45,55 -l error -l xerror -l selftest";

      services.k3s.node = {
        podCIDRs = [
          "2001:cafe:42::/64"
          "10.42.0.0/24"
        ];

        advertisedRoutes = [];

        ips = [
          "2a02:a313:43e4:7080::7dc5"
          "192.168.0.10"
        ];

        externalIPs = [
          "2a02:a313:43e4:7080::7dc5"
        ];
      };

      services.tailscale.extraSetFlags = [
        "--accept-dns=false"
      ];
    };
  };
}
