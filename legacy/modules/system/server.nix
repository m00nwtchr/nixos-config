{
	pkgs,
	lib,
	config,
	...
}: {
	imports = [
		./default.nix
		../ssh.nix
		../chrony.nix
	];

	boot.kernel.sysctl = {
		# ───────────────────── Networking ─────────────────────
		# Accept up to 1 024 queued TCP connections before accept()
		"net.core.somaxconn" = 1024; # prevents connection drops on bursty traffic
		# NIC RX queue length before packets are dropped
		"net.core.netdev_max_backlog" = 16384; # smooths short packet storms
		# Maximum socket buffers (16 MiB)
		"net.core.rmem_max" = 16777216; # cap for receive buffers
		"net.core.wmem_max" = 16777216; # cap for send buffers
		# TCP auto-tuning (min / default / max)
		"net.ipv4.tcp_rmem" = "4096 87380 16777216"; # enable bigger windows when needed
		"net.ipv4.tcp_wmem" = "4096 65536 16777216"; # idem for sends
		# Queues for half-open and accepted connections
		"net.ipv4.tcp_max_syn_backlog" = 8096; # protects against SYN floods
		# Keep full congestion window after idle (better keep-alive latency)
		"net.ipv4.tcp_slow_start_after_idle" = 0;
		# Reuse TIME_WAIT sockets quickly for identical 4-tuples
		"net.ipv4.tcp_tw_reuse" = 1;
		# Flush closed sockets sooner (seconds)
		"net.ipv4.tcp_fin_timeout" = 30;
		# Low-latency queueing + modern congestion control
		"net.core.default_qdisc" = "fq"; # fair-queue packet pacing
		"net.ipv4.tcp_congestion_control" = "bbr"; # BBR v2 improves throughput/latency
		"net.ipv4.tcp_fastopen" = 3;

		# ───────────────────── Memory Management ─────────────────────
		"vm.swappiness" = 1; # avoid swapping unless absolutely necessary
		"vm.vfs_cache_pressure" = 50; # retain inode/dentry caches longer
		"vm.overcommit_memory" = 1; # allow memory over-commit (K8s-friendly)
		"vm.max_map_count" = 262144; # large mmap limit for databases/search
		"vm.dirty_background_ratio" = 5; # start flushing when 5 % RAM is dirty
		"vm.dirty_ratio" = 15; # throttle writes if 15 % RAM dirty

		# ───────────────────── File-system / I-O ─────────────────────
		"fs.file-max" = 2097152; # ~2 M open files system-wide
		"fs.inotify.max_user_instances" = 8192; # many container log watchers
		"fs.inotify.max_user_watches" = 524288; # allow ~0.5 M watched paths

		# ───────────────────── CPU / Scheduler ─────────────────────
		"kernel.sched_autogroup_enabled" = 0; # disable desktop-oriented TTY grouping
		# Make the scheduler reluctant to migrate tasks (µs → ns)
		"kernel.sched_migration_cost_ns" = 5000000; # improve CPU-cache locality

		# ───────────────────── Kernel Stability ─────────────────────
		"kernel.panic" = 10; # auto-reboot 10 s after panic
		"kernel.panic_on_oops" = 1; # treat kernel oops as fatal to avoid limbo
	};

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		nnn # terminal file manager
	];

	users.users.root.openssh.authorizedKeys.keyFiles = [../../secrets/authorized_keys];
	services.openssh = {
		authorizedKeysCommand = "/opt/kanidm_ssh_authorizedkeys %u";
		authorizedKeysCommandUser = "nobody";
		settings = {
			UsePAM = true;
		};
	};

	system.activationScripts.copyFile = ''
		cp ${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys /opt/kanidm_ssh_authorizedkeys
		chown root:root /opt/kanidm_ssh_authorizedkeys
		chmod 0755 /opt/kanidm_ssh_authorizedkeys
	'';

	services = {
		kanidm = {
			package = pkgs.kanidm_1_7;
			# enableClient = true;
			enablePam = false;
			clientSettings = {
				uri = "https://idm.m00nlit.dev";
			};
			unixSettings = {
				version = "2";

				home_alias = "name";
				uid_attr_map = "name";
				gid_attr_map = "name";
				pam_allowed_login_groups = ["unix_admins"];

				kanidm = {
					pam_allowed_login_groups = ["unix_admins"];

					map_group = [
						{
							local = "wheel";
							"with" = "unix_admins";
						}
					];
				};
			};
		};
	};
}
