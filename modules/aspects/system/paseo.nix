{
  den,
  inputs,
  __findFile ? __findFile,
  ...
}: {
  flake-file.inputs.paseo = {
    url = "github:getpaseo/paseo";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.system.paseo = {
    nixos = {
      lib,
      pkgs,
      ...
    }: let
      # Seed once, matching the existing Kubernetes ConfigMap. Runtime edits
      # and migrated state must survive service restarts and host rebuilds.
      seedConfig = pkgs.writeText "paseo-config.json" (builtins.toJSON {
        version = 1;
        agents.providers = {
          claude.enabled = false;
          codex.enabled = false;
          copilot.enabled = false;
          pi.enabled = false;
          omp.enabled = false;
          # hermes = {
          #   extends = "acp";
          #   label = "Hermes";
          #   command = ["/home/paseo/.local/bin/hermes" "acp"];
          # };
        };
        worktrees.root = "/workspace/.worktrees";
      });
    in {
      imports = [inputs.paseo.nixosModules.default];

      services.paseo = {
        enable = true;
        dataDir = "/home/paseo/.paseo";
        listenAddress = "127.0.0.1";
        relay.enable = false;
        hostnames = [".ts.net"];
        inheritUserEnvironment = true;
        environment = {
          HOME = "/home/paseo";
          SHELL = lib.getExe pkgs.bashInteractive;
          HERMES_HOME = "/home/paseo/.hermes";
          PASEO_WEB_UI_ENABLED = "true";
          CARGO_BUILD_JOBS = "4";
          CMAKE_BUILD_PARALLEL_LEVEL = "4";
          MAKEFLAGS = "-j4";
        };
      };

      # Match the UID/GID of the existing Kubernetes PVCs.
      users.groups.paseo.gid = 1000;
      users.users.paseo = {
        uid = 1000;
        home = lib.mkForce "/home/paseo";
        createHome = true;
        shell = pkgs.bashInteractive;
      };

      systemd.tmpfiles.rules = [
        "d /workspace 0750 paseo paseo -"
        "d /var/lib/secrets 0700 root root -"
        "d /var/lib/paseo-runtime 0750 root paseo -"
        "d /home/paseo/.honcho 0700 paseo paseo -"
        "f /home/paseo/.honcho/config.json 0600 paseo paseo -"
      ];

      systemd.services.paseo = {
        unitConfig = {
          ConditionPathExists = "/var/lib/secrets/paseo.env";
          RequiresMountsFor = ["/home/paseo" "/workspace" "/var/lib/paseo-runtime"];
        };
        # Do not use services.paseo.settings: upstream rewrites config.json
        # at each start when that option is non-empty. Preserve runtime edits.
        preStart = ''
          set -euo pipefail
          if ! [[ "''${PASEO_PASSWORD:-}" =~ [^[:space:]] ]]; then
            echo "PASEO_PASSWORD is empty" >&2
            exit 1
          fi
          if ! [[ "''${LITELLM_API_KEY:-}" =~ [^[:space:]] ]]; then
            echo "LITELLM_API_KEY is empty" >&2
            exit 1
          fi
          if [[ ! -e /home/paseo/.paseo/config.json ]]; then
            install -Dm600 ${seedConfig} /home/paseo/.paseo/config.json
          fi
        '';
        serviceConfig = {
          WorkingDirectory = "/workspace";
          # The ConfigMap's Honcho file was mounted read-only in Kubernetes.
          BindReadOnlyPaths = [
            "/var/lib/paseo-runtime/honcho.json:/home/paseo/.honcho/config.json"
          ];
          EnvironmentFile = "/var/lib/secrets/paseo.env";
          MemoryHigh = "16G";
          MemoryMax = "18G";
          CPUWeight = 50;
          IOWeight = 50;
          TasksMax = 8192;
        };
      };

      programs.nix-ld.enable = true;

      environment.systemPackages = with pkgs; [
        # Agents
        opencode

        # General-purpose scripting
        python3
        uv
        nodejs_22
        pnpm
        bashInteractive

        # Version control
        git
        git-lfs
        gh
        lefthook

        # Search and data processing
        ripgrep
        fd
        jq
        yq-go
        sqlite
        tree

        # General utilities
        curl
        wget
        openssh
        rsync
        tmux
        file
        zip
        unzip
        xz
        zstd
        gum
        just

        # Kubernetes and GitOps
        kubectl
        kubernetes-helm
        helmfile
        kustomize
        fluxcd
        kubeconform
        talosctl
        sops
        age

        # Native compilation
        gcc
        gnumake
        pkg-config

        # Documents and media
        poppler-utils
        imagemagick
        ffmpeg
        pandoc
        typst

        # Diagnostics
        htop
        strace
        lsof
        procps
        dnsutils

        # Security
        zizmor

        # Nix
        devenv
        nil
        alejandra
        nix-output-monitor
      ];
    };
  };

  # Host-side routed TAP. microvm.nix creates and removes the device.
  den.aspects.system.paseo-tap = {
    nixos = {
      systemd.network.networks."10-paseo-tap" = {
        matchConfig.Name = "vm-paseo";
        address = ["10.203.67.1/30"];
        linkConfig.RequiredForOnline = "no";
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCP = "no";
          IPv6AcceptRA = false;
          LinkLocalAddressing = "no";
        };
      };

      # NAT follows the host routing table, including changes of uplink.
      networking.nat = {
        enable = true;
        internalInterfaces = ["vm-paseo"];
      };

      # Stateful forwarding: guest-initiated connections and their replies.
      networking.firewall.filterForward = true;
    };
  };

  den.aspects.paseo-vm = {
    includes = [<system/paseo>];
    excludes = [den.aspects.vm];

    microvm = {
      autostart = true;
      restartIfChanged = false;
    };

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 8;
        mem = 20 * 1024;
        balloon = true;
        # Network-independent administrative access from the host.
        vsock = {
          cid = 67;
          ssh.enable = true;
        };
        registerWithMachined = true;
        interfaces = [
          {
            type = "tap";
            id = "vm-paseo";
            mac = "02:00:00:00:67:67";
          }
        ];
        writableStoreOverlay = "/nix/.rw-store";
        volumes = [
          {
            image = "root.img";
            mountPoint = "/";
            label = "paseo-root";
            size = 128 * 1024;
            fsType = "ext4";
          }
          {
            image = "nix-overlay.img";
            mountPoint = config.microvm.writableStoreOverlay;
            label = "paseo-nix";
            size = 64 * 1024;
            fsType = "ext4";
          }
        ];
      };
      fileSystems."/" = {
        neededForBoot = true;
        options = ["defaults"];
      };

      networking.hostName = lib.mkForce "paseo";
      networking.useDHCP = false;
      systemd.network.networks."10-microvm" = {
        matchConfig.MACAddress = "02:00:00:00:67:67";
        address = ["10.203.67.2/30"];
        routes = [{Gateway = "10.203.67.1";}];
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = false;
          LinkLocalAddressing = "no";
        };
      };

      nix = {
        settings = {
          max-jobs = 2;
          cores = 4;
          auto-optimise-store = false;
          trusted-users = lib.mkForce ["root"];
        };
        optimise.automatic = false;
      };
      programs.nh.clean.enable = lib.mkForce false;

      services.tailscale.enable = true;

      # Serve is tailnet-only; Paseo itself stays bound to loopback.
      # Retry until the guest is authenticated and HTTPS is available.
      systemd.services.paseo-serve = {
        description = "Expose Paseo through Tailscale Serve";
        wantedBy = ["tailscaled.service"];
        partOf = ["tailscaled.service"];
        after = ["tailscaled.service" "tailscaled-set.service"];
        wants = ["tailscaled-set.service"];
        path = [config.services.tailscale.package pkgs.jq];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "15s";
          TimeoutStartSec = "45s";
        };
        script = ''
          set -euo pipefail
          tailscale status --json --peers=false | jq -e '.BackendState == "Running"' >/dev/null
          tailscale serve --bg --https=443 http://127.0.0.1:6767
        '';
      };

      services.openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      users.users.root.openssh.authorizedKeys.keyFiles = [
        (toString inputs.self + "/secrets/authorized_keys")
      ];
    };
  };
}
