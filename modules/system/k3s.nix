{
  config,
  lib,
  pkgs,
  ...
}: let
  clusterCIDRs = lib.strings.concatStringsSep "," config.services.k3s.clusterCIDRs;
  serviceCIDRs = lib.strings.concatStringsSep "," config.services.k3s.serviceCIDRs;
  nodePodCIDRs = lib.strings.concatStringsSep "," config.services.k3s.node.podCIDRs;
  nodeIPs = lib.strings.concatStringsSep "," config.services.k3s.node.ips;
  nodeExternalIPs = lib.strings.concatStringsSep "," config.services.k3s.node.externalIPs;
in {
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

  config = {
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
      settings = {
        crio.network.plugin_dirs = [
          "/usr/lib/cni"
        ];
      };
    };

    systemd.services.k3s.path = [pkgs.nftables];
    services.k3s = {
      enable = true;
      token = "K103fe7e5786fff566ecee42be1c1ae502a68f73fe116aeb4adfaaa23d6eec12e26::server:9f32a9df53404822b836974b916460fe";
      extraFlags = lib.strings.concatStringsSep " " ([
          "--container-runtime-endpoint=unix:///run/crio/crio.sock"
          "--node-ip=${nodeIPs}"
          "--node-external-ip=${nodeExternalIPs}"
        ]
        ++ (
          if config.services.k3s.role == "server"
          then [
            "--cluster-cidr=${clusterCIDRs}"
            "--service-cidr=${serviceCIDRs}"
          ]
          else []
        ));
    };
  };
}
