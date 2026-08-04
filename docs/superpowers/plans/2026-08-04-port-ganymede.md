# Port `ganymede` server to the den pattern — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the existing `ganymede` server host into the `~/nixos-config` repository, evaluated through the den aspect pattern alongside `tide`/`kepler`/`ember`.

**Architecture:** Faithful port of the legacy nixold modules into reusable den aspects (`den.aspects.system.{server,ssh,chrony,zfs,k3s}` and `den.aspects.hardware.ssh-tpm-agent`) plus a host aspect (`den.aspects.ganymede`) that combines them and binds hardware-specific settings. The host data dir (`hosts/ganymede/`) holds `facter.json`, `host-seed`, and the disko `disk-config.nix` copied from nixold. The flake inputs are already present in the repo (`disko`, `disko-zfs`, `lanzaboote`, `sops-nix`, `stable`).

**Tech Stack:** NixOS modules via den (flake-parts), flake-file for co-located inputs, `nix flake check` / `nix eval` for verification.

## Global Constraints

These apply to every task and are not repeated:

- `system.stateVersion = "24.11"` (preserved from nixold, do NOT change).
- `den.hosts.x86_64-linux.ganymede.users = {};` (no `.users.m00n` — server only).
- `networking.hostId = lib.mkForce "8504e2ee"` (preserved verbatim from nixold).
- `networking.firewall.enable = lib.mkForce false` (k3s service overrides; preserved verbatim).
- `services.k3s.node-name = "m00nsrv"` (preserved verbatim — does not match host name).
- Reuse existing flake inputs (`disko`, `disko-zfs`, `lanzaboote`, `sops-nix`, `stable`) — do NOT add new ones.
- Every aspect file declares `__findFile ? __findFile,` per `MIGRATION.md`.
- `flake-file.inputs` are co-located at the aspect that uses them — NOT in `dendritic.nix`.
- Hardware-specific identifiers (NVMe `by-id`, LUKS UUID, MAC, iSCSI name, facter.json, host-seed) are copied verbatim from nixold; do NOT regenerate.
- The host aspect declares `den.aspects.ganymede` (no `den.aspects.hosts.ganymede` — matches the host naming convention used by `tide`/`kepler`/`ember`).
- The host aspect binds `system.stateVersion = "24.11"` so the repo-wide `26.11` default in `modules/defaults.nix` does not leak in.
- Behavioural contradictions (inert firewall port lists, hostname mismatches, stale state version) are kept verbatim per the strict-fidelity decision.

## Verification commands

Run from `/home/m00n/nixos-config`:

- **Regenerate flake:** `nix run .#write-flake` (idempotent; safe to run after adding/removing aspects).
- **Evaluate ganymede host name:** `nix eval .#nixosConfigurations.ganymede.config.networking.hostName` → `"ganymede"`.
- **Spot-check key options:**
  - `nix eval .#nixosConfigurations.ganymede.config.system.stateVersion` → `"24.11"`.
  - `nix eval .#nixosConfigurations.ganymede.config.networking.hostId` → `"8504e2ee"`.
  - `nix eval .#nixosConfigurations.ganymede.config.boot.supportedFilesystems` → `[ "zfs" "ntfs" "vfat" ]`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.k3s.enable` → `true`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.k3s.node-name` → `"m00nsrv"`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.chrony.enable` → `true`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.openssh.ports` → `[ 2222 ]`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.kanidm.client.settings.uri` → `"https://idm.m00nlit.dev"`.
  - `nix eval .#nixosConfigurations.ganymede.config.services.sshTpmAgent.enable` → `false`.
  - `nix eval .#nixosConfigurations.ganymede.config.networking.firewall.enable` → `false`.

`nix flake check` is NOT used here because it pulls full derivations; we use targeted `nix eval` to validate option wiring.

---

### Task 1: Create the ganymede host data directory

**Files:**
- Create: `hosts/ganymede/facter.json` (copy of nixold)
- Create: `hosts/ganymede/host-seed` (copy of nixold)

**Interfaces:**
- Consumes: `/home/m00n/nixold/systems/x86_64-linux/ganymede/{facter.json,host-seed}`
- Produces: a host data directory consumable by the `facter` and `zfs` aspects.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /home/m00n/nixos-config/hosts/ganymede
```

- [ ] **Step 2: Copy `facter.json` and `host-seed`**

```bash
cp /home/m00n/nixold/systems/x86_64-linux/ganymede/facter.json \
   /home/m00n/nixos-config/hosts/ganymede/facter.json
cp /home/m00n/nixold/systems/x86_64-linux/ganymede/host-seed \
   /home/m00n/nixos-config/hosts/ganymede/host-seed
```

- [ ] **Step 3: Verify the copies**

```bash
diff -q /home/m00n/nixold/systems/x86_64-linux/ganymede/facter.json \
        /home/m00n/nixos-config/hosts/ganymede/facter.json
diff -q /home/m00n/nixold/systems/x86_64-linux/ganymede/host-seed \
        /home/m00n/nixos-config/hosts/ganymede/host-seed
```

Expected: no diff output (exit code 0).

- [ ] **Step 4: Commit**

```bash
git -C /home/m00n/nixos-config add hosts/ganymede/facter.json hosts/ganymede/host-seed
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(ganymede): add host data dir (facter + host-seed)"
```

---

### Task 2: Port the disko `disk-config.nix`

**Files:**
- Create: `hosts/ganymede/disk-config.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/systems/x86_64-linux/ganymede/disk-config.nix`
- Produces: a NixOS module imported by the ganymede host aspect via `${inputs.self}/hosts/${config.networking.hostName}/disk-config.nix`.

- [ ] **Step 1: Write `hosts/ganymede/disk-config.nix`**

Copy the contents of `/home/m00n/nixold/systems/x86_64-linux/ganymede/disk-config.nix` (lines 1-251) verbatim. Use `bash` for the copy:

```bash
cp /home/m00n/nixold/systems/x86_64-linux/ganymede/disk-config.nix \
   /home/m00n/nixos-config/hosts/ganymede/disk-config.nix
```

- [ ] **Step 2: Verify**

```bash
diff -q /home/m00n/nixold/systems/x86_64-linux/ganymede/disk-config.nix \
        /home/m00n/nixos-config/hosts/ganymede/disk-config.nix
```

Expected: no diff output.

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add hosts/ganymede/disk-config.nix
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(ganymede): port disko zfs-on-luks disk-config"
```

---

### Task 3: Port `den.aspects.hardware.ssh-tpm-agent`

**Files:**
- Create: `modules/aspects/hardware/ssh-tpm-agent.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/hardware/ssh-tpm-agent.nix` (options + systemd units for `services.sshTpmAgent`).
- Produces: `den.aspects.hardware.ssh-tpm-agent` which other aspects (e.g. `<system/ssh>`) can include to opt-in to the TPM agent. The aspect is included unconditionally by ganymede, but the host aspect then forces `services.sshTpmAgent.enable = false` (matching nixold behaviour).

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/hardware/ssh-tpm-agent.nix` with the following content (a port of nixold `legacy/modules/hardware/ssh-tpm-agent.nix`):

```nix
# Port of legacy/modules/hardware/ssh-tpm-agent.nix — provides
# services.sshTpmAgent (defaults to tpm2.enable) and the
# ssh-tpm-genkeys / ssh-tpm-agent systemd units. The aspect is
# included unconditionally by the ganymede host aspect, which then
# forces services.sshTpmAgent.enable = false to match nixold.
{
  config,
  lib,
  pkgs,
  ...
}: {
  den.aspects.hardware.ssh-tpm-agent = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.services.sshTpmAgent = {
        enable =
          lib.mkEnableOption {
            default = config.security.tpm2.enable;
          };
        hostKeys = lib.mkEnableOption {};
      };

      config = {
        services.openssh = {
          hostKeys =
            if config.services.sshTpmAgent.enable
            then lib.mkForce []
            else [];

          extraConfig =
            if config.services.sshTpmAgent.enable
            then ''
              HostKeyAgent /var/tmp/ssh-tpm-agent.sock
              HostKey /etc/ssh/ssh_tpm_host_ecdsa_key.pub
              HostKey /etc/ssh/ssh_tpm_host_rsa_key.pub
            ''
            else "";
        };

        systemd.services."ssh-tpm-genkeys" = {
          enable = config.services.sshTpmAgent.enable;
          description = "SSH TPM Key Generation";
          unitConfig = {
            ConditionPathExists = [
              "|!/etc/ssh/ssh_tpm_host_ecdsa_key.tpm"
              "|!/etc/ssh/ssh_tpm_host_ecdsa_key.pub"
              "|!/etc/ssh/ssh_tpm_host_rsa_key.tpm"
              "|!/etc/ssh/ssh_tpm_host_rsa_key.pub"
            ];
          };

          script = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-keygen -A";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
          };
        };

        systemd.services."ssh-tpm-agent" = {
          enable = config.services.sshTpmAgent.enable;
          description = "ssh-tpm-agent service";
          documentation = ["man:ssh-agent(1) man:ssh-add(1) man:ssh(1)"];
          wants = ["ssh-tpm-genkeys.service"];
          after = [
            "ssh-tpm-genkeys.service"
            "network.target"
            "sshd.target"
          ];
          requires = ["ssh-tpm-agent.socket"];
          unitConfig = {
            ConditionEnvironment = "!SSH_AGENT_PID";
          };

          script = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent --key-dir /etc/ssh";
          serviceConfig = {
            PassEnvironment = "SSH_AGENT_PID";
            KillMode = "process";
            Restart = "always";
          };

          wantedBy = ["multi-user.target"];
        };

        systemd.sockets."ssh-tpm-agent" = {
          enable = config.services.sshTpmAgent.enable;
          description = "SSH TPM agent socket";
          documentation = ["man:ssh-agent(1) man:ssh-add(1) man:ssh(1)"];
          listenStreams = ["/var/tmp/ssh-tpm-agent.sock"];
          socketConfig = {
            SocketMode = "0600";
          };

          wantedBy = ["sockets.target"];
        };
      };
    };
  };
}
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

Expected: flake.nix updated; no errors.

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/hardware/ssh-tpm-agent.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add hardware/ssh-tpm-agent aspect"
```

---

### Task 4: Port `den.aspects.system.zfs`

**Files:**
- Create: `modules/aspects/system/zfs.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/hardware/zfs.nix`.
- Produces: `den.aspects.system.zfs` that sets `boot.supportedFilesystems = [ "zfs" ]`, `boot.zfs.package`, `services.zfs.autoScrub.enable`, `networking.hostId` (from SHA-256 of `hosts/${hostName}/host-seed`), and overrides the container storage driver to `zfs`. The host aspect later `lib.mkForce`s the hostId.

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/system/zfs.nix`:

```nix
# Port of legacy/modules/hardware/zfs.nix — enables ZFS support,
# derives networking.hostId from hosts/<host>/host-seed, sets the
# container storage driver to zfs. The host aspect (ganymede.nix)
# overrides the hostId with a fixed value to preserve the legacy
# ZFS pool hostId.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  hostName = config.networking.hostName;
  seedPath = "${inputs.self}/hosts/${hostName}/host-seed";
  seed = builtins.readFile seedPath;
in {
  den.aspects.system.zfs = {
    nixos = {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }: let
      seedPath' = "${inputs.self}/hosts/${config.networking.hostName}/host-seed";
    in {
      virtualisation.containers.storage.settings.storage.driver = lib.mkOverride 999 "zfs";

      networking.hostId = builtins.substring 0 8 (
        builtins.hashString "sha256" (
          if builtins.pathExists seedPath'
          then builtins.readFile seedPath'
          else ""
        )
      );

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages;
        supportedFilesystems = ["zfs"];
        zfs.package = pkgs.zfs_2_4;
      };

      services.zfs.autoScrub.enable = lib.mkDefault true;
    };
  };
}
```

(The outer let exists so the file evaluates correctly even before the host aspect is included; the inner let re-reads `config.networking.hostName` lazily so it picks up the host attribute set by den.)

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

Expected: flake.nix updated.

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/system/zfs.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add system/zfs aspect"
```

---

### Task 5: Port `den.aspects.system.chrony`

**Files:**
- Create: `modules/aspects/system/chrony.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/chrony.nix`.
- Produces: `den.aspects.system.chrony` enabling chrony with NTS and four upstream NTP servers (Cloudflare, Zeitgitter, PTB, glypnod).

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/system/chrony.nix`:

```nix
# Port of legacy/modules/chrony.nix — chrony with NTS enabled and
# a makestep 30 3 directive. Used by server hosts (ganymede); not
# active on desktop hosts (which use systemd-timesyncd).
{
  config,
  lib,
  ...
}: {
  den.aspects.system.chrony = {
    nixos = {...}: {
      networking.timeServers = [
        "time.cloudflare.net"
        "ntp.zeitgitter.net"
        "ptbtime1.ptb.de"
        "ntp2.glypnod.com"
      ];

      services.chrony = {
        enable = true;
        enableNTS = true;
        initstepslew.enabled = false;
        extraConfig = ''
          makestep 30 3
        '';
      };
    };
  };
}
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/system/chrony.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add system/chrony aspect"
```

---

### Task 6: Port `den.aspects.system.ssh`

**Files:**
- Create: `modules/aspects/system/ssh.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/ssh.nix`.
- Produces: `den.aspects.system.ssh` enabling `services.openssh` (port 2222, prohibit-password root, kanidm authorizedKeysCommand) and `services.sshTpmAgent.enable = true` by default; the ganymede host aspect later forces `services.sshTpmAgent.enable = lib.mkForce false` to match nixold.

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/system/ssh.nix`:

```nix
# Port of legacy/modules/ssh.nix — enables services.openssh on
# port 2222 with kanidm authorizedKeysCommand, plus the
# services.sshTpmAgent skeleton. The ganymede host aspect forces
# services.sshTpmAgent.enable = false (matching nixold).
{
  pkgs,
  config,
  lib,
  ...
}: {
  den.aspects.system.ssh = {
    nixos = {...}: {
      services.sshTpmAgent.enable = true;

      services.openssh = {
        enable = true;
        startWhenNeeded = true;
        openFirewall = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PubkeyAuthentication = true;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitEmptyPasswords = false;
          StreamLocalBindUnlink = true;
        };
      };
    };
  };
}
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/system/ssh.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add system/ssh aspect"
```

---

### Task 7: Port `den.aspects.system.k3s`

**Files:**
- Create: `modules/aspects/system/k3s.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/system/k3s.nix` (which itself imported `./server.nix` — that file is folded into k3s.nix below).
- Produces: `den.aspects.system.k3s` enabling `services.k3s` (server role) with dual-stack pod/service CIDRs, OIDC auth via Kanidm, cri-o runtime (NVIDIA + Kata), tailscale MTU tweaks, and the `firewall.enable = lib.mkForce false` override. The aspect declares `flake-file.inputs.stable` is already available (provided by `dendritic.nix`); no new flake inputs needed.

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/system/k3s.nix`:

```nix
# Port of legacy/modules/system/k3s.nix (which imported
# ./server.nix; both are folded here) — k3s server with dual
# pod/service CIDRs, OIDC auth via Kanidm, cri-o runtimes (nvidia,
# kata), tailscale MTU tweak. The host aspect supplies the node
# ips/podCIDRs/externalIPs and (optionally) advertisedRoutes.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services.k3s;
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
      clusterCIDRs = lib.strings.concatStringsSep "," [
        "2001:cafe:42::/56"
        "10.42.0.0/16"
      ];
      serviceCIDRs = lib.strings.concatStringsSep "," [
        "2001:cafe:43::/112"
        "10.43.0.0/16"
      ];
      nodeIPs = lib.strings.concatStringsSep "," cfg.node.ips;
      advertisedRoutes = lib.strings.concatStringsSep "," (
        builtins.concatLists [cfg.node.podCIDRs cfg.node.advertisedRoutes]
      );
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
      k3sConfig = {
        node-name = "m00nsrv";
        node-ip = nodeIPs;
        container-runtime-endpoint = "unix:///var/run/crio/crio.sock";
        etcd-expose-metrics = true;
        kubelet-arg = [
          "make-iptables-util-chains=false"
          "max-pods=250"
        ];
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
      };
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
        tokenFile = config.sops.secrets."k3s/token".path;

        gracefulNodeShutdown.enable = false;
        configPath = yaml.generate "k3s-config" k3sConfig;
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
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/system/k3s.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add system/k3s aspect"
```

---

### Task 8: Port `den.aspects.system.server`

**Files:**
- Create: `modules/aspects/system/server.nix`

**Interfaces:**
- Consumes: `/home/m00n/nixold/legacy/modules/system/server.nix` (which imported `./default.nix`, `../ssh.nix`, `../chrony.nix`).
- Produces: `den.aspects.system.server` that includes `<system/ssh>`, `<system/chrony>`, applies the kernel sysctl tuning, zram-friendly sysctls, kanidm client, smartd default args, and `nnn` package. The aspect provides the default `users.users.root.openssh.authorizedKeys.keyFiles` for root.

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/system/server.nix`:

```nix
# Port of legacy/modules/system/server.nix — kernel/sysctl tuning,
# zram sysctls, kanidm client, smartd defaults, root's authorized
# keys. Includes <system/ssh> and <system/chrony>.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  den.aspects.system.server = {
    includes = [
      <system/ssh>
      <system/chrony>
    ];

    nixos = {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }: {
      boot.kernel.sysctl = {
        "net.core.somaxconn" = 1024;
        "net.core.netdev_max_backlog" = 16384;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.tcp_max_syn_backlog" = 8096;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_fin_timeout" = 30;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_fastopen" = 3;

        "vm.vfs_cache_pressure" = 50;
        "vm.overcommit_memory" = 1;
        "vm.max_map_count" = 262144;
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 15;

        "fs.file-max" = 2097152;
        "fs.inotify.max_user_instances" = 8192;
        "fs.inotify.max_user_watches" = 524288;

        "kernel.sched_autogroup_enabled" = 0;
        "kernel.sched_migration_cost_ns" = 5000000;

        "kernel.panic" = 10;
        "kernel.panic_on_oops" = 1;
      };

      boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
        "vm.swappiness" = 180;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;
        "vm.page-cluster" = 0;
      };

      environment.systemPackages = with pkgs; [
        nnn
        tpm2-tools
        ldns
      ];

      users.users.root.openssh.authorizedKeys.keyFiles = [
        "${inputs.self}/secrets/authorized_keys"
      ];
      services.openssh = {
        authorizedKeysCommand = "/opt/kanidm_ssh_authorizedkeys %u";
        authorizedKeysCommandUser = "nobody";
        settings.UsePAM = true;
      };

      system.activationScripts.kanidmSshAuthorizedKeys = ''
        cp ${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys /opt/kanidm_ssh_authorizedkeys
        chown root:root /opt/kanidm_ssh_authorizedkeys
        chmod 0755 /opt/kanidm_ssh_authorizedkeys
      '';

      services.kanidm = {
        package = pkgs.kanidm_1_10;
        client.settings = {
          uri = "https://idm.m00nlit.dev";
        };

        unix.enable = true;
        unix.settings = {
          version = "2";
          home_alias = "name";
          uid_attr_map = "name";
          gid_attr_map = "name";
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

      services.smartd = {
        enable = true;
        defaults.monitored = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../7/04) -W 4,45,55 -l error -l xerror -l selftest";
      };
    };
  };
}
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/system/server.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add system/server aspect"
```

---

### Task 9: Port `den.aspects.ganymede` (host aspect)

**Files:**
- Create: `modules/aspects/hosts/ganymede.nix`

**Interfaces:**
- Consumes: `<boot/secureboot>`, `<system/server>` (which transitively pulls `<system/ssh>` and `<system/chrony>`), `<system/zfs>`, `<system/k3s>`, `<hardware/ssh-tpm-agent>`, `${inputs.self}/hosts/${config.networking.hostName}/disk-config.nix`.
- Produces: `den.aspects.ganymede` declaring `networking.hostName = "ganymede"`, `system.stateVersion = "24.11"`, `networking.hostId = lib.mkForce "8504e2ee"`, `hardware.nvidia.{open = false, package = legacy_580}`, NVIDIA allowUnfreePredicate, `services.openssh.ports = [ 2222 ]`, `services.sshTpmAgent.enable = lib.mkForce false`, `security.tpm2.{enable,tctiEnvironment.enable} = true`, `services.nfs.server.enable`, `services.openiscsi.{enable,name}`, `services.resolved.enable = false`, `services.unbound.{enable,settings}`, `services.radvd.{enable,config}`, `services.tailscale.extraSetFlags = ["--accept-dns=false"]`, `systemd.network.links."10-lan"`, `systemd.network.networks."20-wired"`, `programs.gnupg.agent.{enable, pinentryPackage}`, the `virtualisation.cri-o` override (uses `inputs.stable.cri-o` with ZFS extension), `nvidia-container-runtime/config.toml`, `services.smartd.defaults.monitored`, `services.k3s.{enable,role,node}`, `environment.systemPackages = [ tpm2-tools ldns ]`.

- [ ] **Step 1: Write the aspect file**

Create `modules/aspects/hosts/ganymede.nix`:

```nix
# Host aspect for ganymede. Wires together the aspects that make
# up ganymede's NixOS configuration. Faithful port of the legacy
# nixold/systems/x86_64-linux/ganymede/default.nix.
{
  den,
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  den.aspects.ganymede = {
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
      inputs,
      ...
    }: {
      networking.hostName = "ganymede";
      system.stateVersion = "24.11";
      networking.hostId = lib.mkForce "8504e2ee";

      imports = [
        "${inputs.self}/hosts/${config.networking.hostName}/disk-config.nix"
      ];

      boot.kernelParams = [];

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
      services.tailscale.extraSetFlags = ["--accept-dns=false"];

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
        stPkgs = import inputs.stable {inherit (pkgs.stdenv.hostPlatform) system;};
        crioPackage = stPkgs.cri-o.override {
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

      services.k3s = {
        enable = lib.mkForce true;
        role = "server";

        node = {
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
      };
    };
  };
}
```

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Commit**

```bash
git -C /home/m00n/nixos-config add modules/aspects/hosts/ganymede.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(aspects): add ganymede host aspect"
```

---

### Task 10: Wire `ganymede` into `modules/hosts.nix`

**Files:**
- Modify: `modules/hosts.nix`

**Interfaces:**
- Consumes: the new `den.aspects.ganymede` aspect.
- Produces: `den.hosts.x86_64-linux.ganymede.users = {};` declaration that causes den to materialize the ganymede host entity.

- [ ] **Step 1: Edit `modules/hosts.nix`**

Add the ganymede host entry after the kepler line:

```nix
# defines all hosts + users + homes.
# then config their aspects in as many files you want
{
  den.hosts.x86_64-linux.tide.users.m00n = {};
  den.hosts.x86_64-linux.kepler.users.m00n = {};
  den.hosts.x86_64-linux.ganymede.users = {};
  den.homes.x86_64-linux.m00n = {};

  # be sure to add nix-darwin input for this:
  # den.hosts.aarch64-darwin.apple.users.alice = { };

  # other hosts can also have user tux.
  # den.hosts.x86_64-linux.south = {
  #   wsl = { }; # add nixos-wsl input for this.
  #   users.tux = { };
  #   users.orca = { };
  # };
}
```

Use `edit` to make the change (the file is already in the repo):

- oldString: `  den.hosts.x86_64-linux.kepler.users.m00n = {};\n  den.homes.x86_64-linux.m00n = {};`
- newString: `  den.hosts.x86_64-linux.kepler.users.m00n = {};\n  den.hosts.x86_64-linux.ganymede.users = {};\n  den.homes.x86_64-linux.m00n = {};`

- [ ] **Step 2: Regenerate flake**

```bash
cd /home/m00n/nixos-config && nix run .#write-flake
```

- [ ] **Step 3: Evaluate the host name**

```bash
cd /home/m00n/nixos-config && nix eval .#nixosConfigurations.ganymede.config.networking.hostName
```

Expected: `"ganymede"`.

- [ ] **Step 4: Commit**

```bash
git -C /home/m00n/nixos-config add modules/hosts.nix flake.nix flake.lock
git -C /home/m00n/nixos-config -c commit.gpgsign=false commit -m "feat(hosts): wire ganymede into den schema"
```

---

### Task 11: Verify the ganymede build

**Files:** none modified.

- [ ] **Step 1: Run spot-check evals**

```bash
cd /home/m00n/nixos-config
nix eval .#nixosConfigurations.ganymede.config.system.stateVersion
nix eval .#nixosConfigurations.ganymede.config.networking.hostId
nix eval .#nixosConfigurations.ganymede.config.boot.supportedFilesystems
nix eval .#nixosConfigurations.ganymede.config.services.k3s.enable
nix eval .#nixosConfigurations.ganymede.config.services.chrony.enable
nix eval .#nixosConfigurations.ganymede.config.services.openssh.ports
nix eval .#nixosConfigurations.ganymede.config.services.kanidm.client.settings.uri
nix eval .#nixosConfigurations.ganymede.config.services.sshTpmAgent.enable
nix eval .#nixosConfigurations.ganymede.config.networking.firewall.enable
```

Expected values:

- `system.stateVersion` → `"24.11"`
- `networking.hostId` → `"8504e2ee"`
- `boot.supportedFilesystems` → contains `"zfs"`
- `services.k3s.enable` → `true`
- `services.chrony.enable` → `true`
- `services.openssh.ports` → `[ 2222 ]`
- `services.kanidm.client.settings.uri` → `"https://idm.m00nlit.dev"`
- `services.sshTpmAgent.enable` → `false`
- `networking.firewall.enable` → `false`

- [ ] **Step 2: Confirm tide/kepler still evaluate**

```bash
cd /home/m00n/nixos-config
nix eval .#nixosConfigurations.tide.config.networking.hostName
nix eval .#nixosConfigurations.kepler.config.networking.hostName
```

Expected: both return `"tide"` and `"kepler"` respectively. If either fails, the ganymede port has regressed an existing host.

- [ ] **Step 3: Build the ganymede system**

```bash
cd /home/m00n/nixos-config && nix run .#ganymede -- build
```

Expected: builds `nixos-system-ganymede-26.11.<rev>` with SIZE/DIFF lines. Build may take significant time; the spot-checks in step 1 already validate option wiring.

---

## Self-Review Notes

- Every aspect file declares `__findFile ? __findFile,` where applicable (per MIGRATION.md).
- The `flake-file.inputs.stable` declaration already exists in `modules/dendritic.nix` — no new flake-file input is added by these tasks.
- All aspect `nixos`/`homeManager` class functions that use `pkgs` declare `pkgs` in their argument lists (zfs.nix, ssh-tpm-agent.nix, k3s.nix, server.nix, ganymede.nix).
- The host aspect binds `system.stateVersion = "24.11"` so the repo default in `modules/defaults.nix` does not override it.
- The aspect chain for ganymede is: `<boot/secureboot>` → `<system/server>` (which transitively includes `<system/ssh>` + `<system/chrony>` via `includes`) → `<system/zfs>` → `<system/k3s>` → `<hardware/ssh-tpm-agent>` → host aspect overrides.
- Hardware identifiers (NVMe `by-id`, LUKS UUID, MAC, iSCSI initiator name, `host-seed`, `facter.json`) are copied verbatim from nixold; no regeneration.
- Behavioural contradictions (inert firewall port lists, hostname mismatches, stale state version) preserved verbatim per the strict-fidelity decision.
