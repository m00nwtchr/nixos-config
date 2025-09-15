# https://search.nixos.org/options
{
	config,
	lib,
	pkgs,
	...
}: {
	imports = [
		../../modules/efi
		../../modules/system/k3s.nix

		./hardware-configuration.nix
	];

	# Use the systemd-boot EFI boot loader.
	boot.kernelPackages = pkgs.linuxPackages_latest;
	boot.kernelParams = [
		"console=tty1"
		"console=ttyS0"
		"nvme.shutdown_timeout=10"
		"libiscsi.debug_libiscsi_eh=1"
		"crash_kexec_post_notifiers"
	];

	networking.hostName = "bastion"; # Define your hostname.

	networking.hosts = {
		"100.116.45.53" = ["m00nlit.dev"];
		"fd7a:115c:a1e0::f201:2d35" = ["m00nlit.dev"];
	};

	networking.firewall = {
		allowedTCPPorts = [
			25565
			443
			80
		];
		allowedUDPPorts = [
			25565
			443
		];
	};

	security.tpm2.enable = lib.mkForce false;
	services.sshTpmAgent.enable = lib.mkForce false;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [];

	# 150.230.150.181

	services.k3s = {
		role = "agent";
		serverAddr = "https://m00nsrv:6443";

		node = {
			podCIDRs = [
				"2001:cafe:42:1::/64"
				"10.42.1.0/24"
			];

			ips = [
				"fd7a:115c:a1e0::c801:4612"
				"100.77.70.18"
			];

			externalIPs = [
				"2603:c020:8014:300:5bb8:9209:140a:bf5c"
				"10.0.0.87"
			];
		};
	};

	services.ollama.enable = true;

	services.haproxy = {
		enable = true;

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
	system.stateVersion = "24.11"; # Did you read the comment?
}
