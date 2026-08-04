# k3s aspect — server role with dual-stack pod/service CIDRs, OIDC
# auth via Kanidm, cri-o runtime, tailscale MTU tweak. The host
# aspect supplies nodeIP/externalIPs via the standard NixOS k3s
# module options. The rest of the k3s config is passed via
# `extraFlags` since the modern NixOS k3s module is a thin wrapper
# around the k3s binary that exposes a few high-level options and
# forwards everything else through `extraFlags`.
{
  __findFile ? __findFile,
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  yaml = pkgs.formats.yaml {};
in {
  den.aspects.system.k3s = {
    nixos = {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }: let
      authConfig = {
        apiVersion = "apiserver.config.k8s.io/v1";
        kind = "AuthenticationConfiguration";
        jwt = [{
          issuer.url = "https://idm.m00nlit.dev/oauth2/openid/kubernetes";
          issuer.audiences = ["kubernetes"];
          claimMappings = {
            username = {claim = "name"; prefix = "oidc:";};
            groups = {claim = "groups"; prefix = "oidc:";};
          };
        }];
        anonymous = {
          enabled = true;
          conditions = [
            {path = "/livez";}
            {path = "/readyz";}
            {path = "/healthz";}
            {path = "/.well-known/openid-configuration";}
            {path = "/openid/v1/jwks";}
          ];
        };
      };
      authConfigYaml = yaml.generate "k8s-auth-config" authConfig;
    in {
      boot.kernel.sysctl = {
        "net.ipv4.ip_local_reserved_ports" = "30000-32767";
      };

      networking.firewall.enable = lib.mkForce false;

      systemd.services.tailscale-net-tweak = {
        description = "Tailscale performance tuning";
        wantedBy = ["multi-user.target"];
        wants = ["network-online.target"];
        after = ["network-online.target"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "tailscale-net-tweak" ''
            NETDEV=$(${pkgs.iproute2}/bin/ip -o route show default | ${pkgs.gawk}/bin/awk '{print $5}')
            ${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };

      services.tailscale = {
        enable = true;
        extraSetFlags = [
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
          crio.image = {
            short_name_mode = "disabled";
          };
          crio.network.plugin_dirs = ["/opt/cni/bin"];
          crio.runtime.hooks_dir = ["/usr/share/containers/oci/hooks.d"];
        };
      };

      virtualisation.containerd = {
        enable = false;
        settings = lib.mkForce {
          version = 3;
          plugins = {
            "io.containerd.cri.v1.images" = {
              snapshotter = "zfs";
            };
            "io.containerd.cri.v1.runtime" = {
              cni = {
                bin_dir = "/opt/cni/bin";
                conf_dir = "/etc/cni/net.d/";
              };
              containerd = {
                default_runtime_name = "crun";
                runtimes.crun = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    BinaryName = "${pkgs.crun}/bin/crun";
                    SystemdCgroup = true;
                  };
                };
              };
            };
          };
        };
      };

      sops.secrets."k3s/token".sopsFile = "${inputs.self}/secrets/k3s.yaml";

      systemd.services.k3s.path = [pkgs.nftables];

      services.k3s = {
        enable = true;
        package = pkgs.k3s;
        role = "server";
        tokenFile = config.sops.secrets."k3s/token".path;

        gracefulNodeShutdown.enable = false;

        # Modern NixOS k3s module is a thin wrapper. The k3s binary
        # accepts ~all settings via CLI flags. The `extraFlags` list
        # maps directly to k3s command-line arguments. Auth config
        # and tls-san, dual-CIDR, kubelet args, and disabled
        # built-ins all flow through this channel.
        extraFlags = [
          "--node-name=m00nsrv"
          "--container-runtime-endpoint=unix:///var/run/crio/crio.sock"
          "--etcd-expose-metrics=true"
          "--cluster-cidr=2001:cafe:42::/56,10.42.0.0/16"
          "--service-cidr=2001:cafe:43::/112,10.43.0.0/16"
          "--flannel-backend=none"
          "--disable-network-policy"
          "--disable-kube-proxy"
          "--tls-san=k8s.m00nlit.dev"
          "--kubelet-arg=make-iptables-util-chains=false"
          "--kubelet-arg=max-pods=250"
          "--kube-apiserver-arg=authentication-config=${authConfigYaml}"
          "--kube-apiserver-arg=service-account-issuer=https://k8s.m00nlit.dev"
          "--kube-apiserver-arg=service-account-jwks-uri=https://k8s.m00nlit.dev/openid/v1/jwks"
          "--kube-apiserver-arg=feature-gates=MutatingAdmissionPolicy=true"
          "--kube-apiserver-arg=runtime-config=admissionregistration.k8s.io/v1beta1=true"
        ]
        ++ map (d: "--disable=${d}") [
          "traefik"
          "metrics-server"
          "servicelb"
          "coredns"
          "local-storage"
        ];

        extraKubeletConfig = {
          memorySwap.swapBehavior = "LimitedSwap";
          imageMaximumGCAge = "12h";
          cgroupDriver = "systemd";
          featureGates = {
            ImageVolume = true;
          };
        };
      };
    };
  };
}
