{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./server.nix
  ];

  options.services.k3s = {
    clusterCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "2001:cafe:42::/56"
        "10.42.0.0/16"
      ];
    };

    serviceCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "2001:cafe:43::/112"
        "10.43.0.0/16"
      ];
    };

    node = {
      podCIDRs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "2001:cafe:42::/64"
          "10.42.0.0/24"
        ];
      };

      ips = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };

      externalIPs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = let
    clusterCIDRs = lib.strings.concatStringsSep "," config.services.k3s.clusterCIDRs;
    serviceCIDRs = lib.strings.concatStringsSep "," config.services.k3s.serviceCIDRs;
    nodePodCIDRs = lib.strings.concatStringsSep "," config.services.k3s.node.podCIDRs;
    nodeIPs = lib.strings.concatStringsSep "," config.services.k3s.node.ips;
    nodeExternalIPs = lib.strings.concatStringsSep "," config.services.k3s.node.externalIPs;

    k3sConfig =
      {
        node-ip = nodeIPs;
        node-external-ip = nodeExternalIPs;

        container-runtime-endpoint = "unix:///var/run/crio/crio.sock";

        kubelet-arg = [
          "make-iptables-util-chains=false"
        ];
      }
      // (
        if config.services.k3s.role == "server"
        then {
          disable = ["traefik" "metrics-server" "servicelb"];

          cluster-cidr = clusterCIDRs;
          service-cidr = serviceCIDRs;

          advertise-address = builtins.elemAt config.services.k3s.node.ips 0;

          flannel-backend = "none";
          disable-network-policy = true;
          disable-kube-proxy = true;

          tls-san = "k8s.m00nlit.dev";

          kube-apiserver-arg = [
            "oidc-issuer-url=https://idm.m00nlit.dev/oauth2/openid/kubernetes"
            "oidc-client-id=kubernetes"
            "oidc-signing-algs=ES256"
            "oidc-username-prefix=oidc:"
            "oidc-groups-prefix=oidc:"
            "oidc-username-claim=name"
            "oidc-groups-claim=groups"
          ];
        }
        else {}
      );
  in {
    # boot.kernelPatches = [
    #   {
    #     name = "rt-group-sched";
    #     patch = null;
    #     extraConfig = ''
    #       RT_GROUP_SCHED y
    #     '';
    #   }
    # ];

    networking.firewall.enable = lib.mkForce false;
    networking.nftables.ruleset = ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority 0;
          # Redirect HTTP to NodePort 30080
          tcp dport 80 redirect to :30080
          # Redirect HTTPS to NodePort 30443
          tcp dport 443 redirect to :30443
        }

        chain output {
          type nat hook output priority 0;
        }
      }
    '';

    networking.localCommands = ''
      NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
      ${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
    '';

    services.tailscale = {
      enable = true;
      extraSetFlags = [
        "--advertise-routes=${nodePodCIDRs}"
        "--accept-routes"
      ];
    };
    systemd.services.tailscaled.serviceConfig.Environment = ["TS_DEBUG_MTU=1420"];

    boot.kernelModules = [
      "ip6_tables"
      "ip6table_mangle"
      "ip6table_raw"
      "ip6table_filter"
    ];

    virtualisation.cri-o = {
      enable = true;

      storageDriver = config.virtualisation.containers.storage.settings.storage.driver;
      settings = {
        crio.network.plugin_dirs = [
          "/usr/lib/cni"
        ];
      };
    };

    sops.secrets."k3s/token".sopsFile = ../../secrets/k3s.yaml;

    systemd.services.k3s.path = [pkgs.nftables];
    services.k3s = {
      enable = true;
      tokenFile = config.sops.secrets."k3s/token".path;

      gracefulNodeShutdown.enable = true;
      configPath = (pkgs.formats.yaml {}).generate "k3s-config" k3sConfig;
      extraKubeletConfig = {
        memorySwap.swapBehavior = "LimitedSwap";
        imageMaximumGCAge = "12h";
      };
    };
  };
}
