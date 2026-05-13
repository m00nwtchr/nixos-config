{
	config,
	lib,
	pkgs,
	inputs,
	...
}: with lib; let
	cfg = config.services.k3s;
	yaml = pkgs.formats.yaml {};
in {
	imports = [
		./server.nix
	];

	options.services.k3s = {
		clusterCIDRs =
			lib.mkOption {
				type = lib.types.listOf lib.types.str;
				default = [
					"2001:cafe:42::/56"
					"10.42.0.0/16"
				];
			};

		serviceCIDRs =
			lib.mkOption {
				type = lib.types.listOf lib.types.str;
				default = [
					"2001:cafe:43::/112"
					"10.43.0.0/16"
				];
			};

		authConfig = mkOption {
			type = with types; attrsOf yaml.type;
			default = {
				apiVersion = "apiserver.config.k8s.io/v1";
				kind = "AuthenticationConfiguration";
			};
		};

		node = {
			podCIDRs =
				lib.mkOption {
					type = lib.types.listOf lib.types.str;
					default = [
						"2001:cafe:42::/64"
						"10.42.0.0/24"
					];
				};

			advertisedRoutes =
				lib.mkOption {
					type = lib.types.listOf lib.types.str;
					default = [
					];
				};

			ips =
				lib.mkOption {
					type = lib.types.listOf lib.types.str;
				};

			externalIPs =
				lib.mkOption {
					type = lib.types.listOf lib.types.str;
				};
		};

		
	};

	config = let
		clusterCIDRs = lib.strings.concatStringsSep "," cfg.clusterCIDRs;
		serviceCIDRs = lib.strings.concatStringsSep "," cfg.serviceCIDRs;
		# nodePodCIDRs = lib.strings.concatStringsSep "," cfg.node.podCIDRs;
		nodeIPs = lib.strings.concatStringsSep "," cfg.node.ips;
		nodeExternalIPs = lib.strings.concatStringsSep "," cfg.node.externalIPs;

		advertisedRoutes =
			lib.strings.concatStringsSep "," (
				builtins.concatLists [
					cfg.node.podCIDRs
					cfg.node.advertisedRoutes
				]
			);


		authConfig = {
			jwt = [{
				issuer.url = "https://idm.m00nlit.dev/oauth2/openid/kubernetes";
				issuer.audiences = ["kubernetes"];
				claimMappings = {
					username = { claim = "name"; prefix = "oidc:"; };
					groups = { claim = "groups"; prefix = "oidc:"; };
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
		} // cfg.authConfig;

		k3sConfig =
			{
				node-name = "m00nsrv";
					# lib.mkIf (config.networking.hostName == "ganymede")
					# "m00nsrv";
				node-ip = nodeIPs;
				# node-external-ip = nodeExternalIPs;

				container-runtime-endpoint = "unix:///var/run/crio/crio.sock";
				etcd-expose-metrics = true;

				kubelet-arg = [
					"make-iptables-util-chains=false"
					"max-pods=250"
				];
			}
			// (
				if cfg.role == "server"
				then {
					disable = [
						"traefik"
						"metrics-server"
						"servicelb"
						"coredns"
						"local-storage"
					];

					cluster-cidr = clusterCIDRs;
					service-cidr = serviceCIDRs;

					advertise-address = builtins.elemAt cfg.node.ips 0;

					flannel-backend = "none";
					disable-network-policy = true;
					disable-kube-proxy = true;

					tls-san = "k8s.m00nlit.dev";

					kube-apiserver-arg = let
						authConfigYaml = yaml.generate "k8s-auth-config" authConfig;
					in [
						"authentication-config=${authConfigYaml}"
						"service-account-issuer=https://k8s.m00nlit.dev"
						"service-account-jwks-uri=https://k8s.m00nlit.dev/openid/v1/jwks"

						"feature-gates=MutatingAdmissionPolicy=true"
						"runtime-config=admissionregistration.k8s.io/v1beta1=true"
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

		boot.kernel.sysctl = {
			"net.ipv4.ip_local_reserved_ports" = "30000-32767"; # reserve NodePort range
		};

		networking.firewall.enable = lib.mkForce false;
		# networking.nftables.tables.ingress = {
		#   family = "ip";
		#   content = ''
		#     chain prerouting {
		#       type nat hook prerouting priority 0;
		#       # Redirect HTTP to NodePort 30080
		#       tcp dport 80 redirect to :30080
		#       # Redirect HTTPS to NodePort 30443
		#       tcp dport 443 redirect to :30443
		#     }

		#     chain output {
		#       type nat hook output priority 0;
		#     }
		#   '';
		# };

		systemd.services.tailscale-net-tweak = {
			description = "Tailscale performance tuning";
			wantedBy = ["multi-user.target"];
			wants = ["network-online.target"];
			after = ["network-online.target"];

			serviceConfig = {
				Type = "oneshot";
				ExecStart =
					pkgs.writeShellScript "tailscale-net-tweak" ''
						NETDEV=$(${pkgs.iproute2}/bin/ip -o route show default | ${pkgs.gawk}/bin/awk '{print $5}')
						${pkgs.ethtool}/bin/ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
					'';
			};
		};

		services.tailscale = {
			enable = true;
			extraSetFlags = [
				"--advertise-routes=${advertisedRoutes}"
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
				crio.network.plugin_dirs = [
					"/opt/cni/bin"
				];
				crio.runtime.hooks_dir = [
					"/usr/share/containers/oci/hooks.d"
				];
			};
		};

		virtualisation.containerd = {
			enable = false;

			settings =
				lib.mkForce {
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
			tokenFile = config.sops.secrets."k3s/token".path;

			gracefulNodeShutdown.enable = false;
			configPath = yaml.generate "k3s-config" k3sConfig;
			extraKubeletConfig = {
				memorySwap.swapBehavior = "LimitedSwap";
				imageMaximumGCAge = "12h";

				cgroupDriver = "systemd";
				featureGates = {
					ImageVolume = true;
					# PodAndContainerStatsFromCRI = true;
				};
			};
		};
	};
}
