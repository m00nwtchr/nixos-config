# Port `ganymede` server to the den pattern

Date: 2026-08-04
Status: Approved (in-session)
Owner: m00n

## Goal

Bring `ganymede` (the existing NixOS server) into `/home/m00n/nixos-config` so that the host builds through the repository's den pattern alongside `tide`, `kepler`, and `ember`, while preserving the runtime behavior that the legacy configuration produces on the existing hardware.

## Decisions captured during brainstorming

- **Port fidelity:** exact host port. Machine-specific disks, network, ZFS pools, k3s, NVIDIA, services, and secrets wiring are translated verbatim.
- **User wiring:** server only. `den.hosts.x86_64-linux.ganymede.users = {};` (no `.users.m00n`).
- **State version:** preserve `system.stateVersion = "24.11"`.
- **Behavior cleanup:** strict fidelity. Inert firewall port lists, hostname mismatches, and similar contradictions are left as-is.
- **Approach:** reusable aspects. Shared behavior becomes new den aspects; host-specific data lives in the host aspect and data directory.

## Resulting layout

```
/home/m00n/nixos-config/
├── modules/
│   ├── hosts.nix                                  # add ganymede entry
│   ├── defaults.nix                               # unchanged
│   ├── dendritic.nix                              # unchanged
│   └── aspects/
│       ├── hosts/
│       │   └── ganymede.nix                       # NEW: den.aspects.ganymede
│       ├── system/
│       │   ├── server.nix                         # NEW: den.aspects.system.server
│       │   ├── ssh.nix                            # NEW: den.aspects.system.ssh
│       │   ├── chrony.nix                         # NEW: den.aspects.system.chrony
│       │   ├── zfs.nix                            # NEW: den.aspects.system.zfs
│       │   └── k3s.nix                            # NEW: den.aspects.system.k3s
│       ├── hardware/
│       │   └── ssh-tpm-agent.nix                  # NEW: den.aspects.hardware.ssh-tpm-agent
│       └── boot/secureboot.nix                    # reused as-is
└── hosts/
    └── ganymede/                                  # NEW data dir
        ├── disk-config.nix                        # ported from nixold
        ├── facter.json                            # copied from nixold
        ├── host-seed                              # copied from nixold
        └── secrets/                                # absent → sops pathExists guard no-ops
```

## Host wiring (`modules/hosts.nix`)

Append a sibling entry for `ganymede` next to the existing hosts:

```nix
den.hosts.x86_64-linux.tide.users.m00n = {};
den.hosts.x86_64-linux.kepler.users.m00n = {};
den.hosts.x86_64-linux.ganymede.users = {};
```

## Data dir (`hosts/ganymede/`)

- Copy `facter.json` and `host-seed` verbatim from `/home/m00n/nixold/systems/x86_64-linux/ganymede/`.
- Place `disk-config.nix` here to mirror the nixold structure. The host aspect imports it via `${inputs.self}/hosts/${config.networking.hostName}/disk-config.nix`.
- Create `secrets/` directory; if `secrets/default.yaml` is absent, the sops aspect's `pathExists` guard already short-circuits, matching nixold behavior.

## Aspect responsibilities

Each new aspect declares `__findFile ? __findFile` in its argument list and includes the flake inputs it needs (per `MIGRATION.md`).

### `den.aspects.system.server` (`modules/aspects/system/server.nix`)

Pulls in `<system/ssh>`, `<system/chrony>`, and applies the base server profile:

- Kernel sysctl tuning from nixold `legacy/modules/system/server.nix` (somaxconn, BBR, fq, swap overcommit, file-max, inotify watches, sched_migration_cost, `vm.max_map_count=262144`, `kernel.panic=10`, `panic_on_oops=1`).
- `boot.zramSwap.enable = true` plus zram-friendly vm sysctls.
- Nix daemon settings (experimental features, xdg base dirs, weekly GC, optimise).
- `environment.etc."current-nixos".source = ${inputs.self}`.
- Locale/keymap (`Europe/Warsaw`, `pl`).
- `services.smartd.enable = true` with the nixold default argument set.
- Packages: `tpm2-tools`, `ldns`, `nnn`.
- Kanidm client (`kanidm_1_10`, `uri = "https://idm.m00nlit.dev"`, `unix.enable = true`, group mapping `wheel ↔ unix_admins`).
- Activates `/opt/kanidm_ssh_authorizedkeys` for root's `authorizedKeysCommand`.
- Sets `services.tailscale.extraSetFlags = ["--accept-dns=false"]`.

### `den.aspects.system.ssh` (`modules/aspects/system/ssh.nix`)

Ported from nixold `legacy/modules/ssh.nix`:

- `services.openssh.enable = true`, `ports = [ 2222 ]`.
- `PermitRootLogin = "prohibit-password"`, password/kbd auth disabled.
- `authorizedKeysCommand = "/opt/kanidm_ssh_authorizedkeys %u"` plus `authorizedKeysCommandUser = "nobody"`.
- Root additionally loads `${inputs.self}/secrets/authorized_keys`.
- Forces `services.sshTpmAgent.enable = lib.mkForce false` (matches nixold).

### `den.aspects.system.chrony` (`modules/aspects/system/chrony.nix`)

Ported from nixold `legacy/modules/chrony.nix`:

- `services.chrony.enable = true`.
- NTS enabled, `makestep 30 3`.
- Upstreams: `time.cloudflare.net`, `ntp.zeitgitter.net`, `ptbtime1.ptb.de`, `ntp2.glypnod.com`.

### `den.aspects.system.zfs` (`modules/aspects/system/zfs.nix`)

Ported from nixold `legacy/modules/hardware/zfs.nix`:

- Derives `networking.hostId` from SHA-256 of `hosts/${config.networking.hostName}/host-seed`.
- Enables `boot.supportedFilesystems = [ "zfs" ]`.
- The host aspect later `lib.mkForce`s the hostId to preserve the existing value.

### `den.aspects.system.k3s` (`modules/aspects/system/k3s.nix`)

Ported from nixold `legacy/modules/system/k3s.nix` and `legacy/modules/system/k3s/server.nix`:

- `services.k3s.role = "server"`; package `pkgs.k3s`; token from `sops.secrets."k3s/token".path`.
- Disables built-ins: `traefik`, `metrics-server`, `servicelb`, `coredns`, `local-storage`.
- Dual CIDR: `cluster-cidr = "2001:cafe:42::/56,10.42.0.0/16"`, `service-cidr = "2001:cafe:43::/112,10.43.0.0/16"`, `flannel-backend = "none"`, `disable-network-policy = true`, `disable-kube-proxy = true`.
- `tls-san = "k8s.m00nlit.dev"`.
- Node: `podCIDRs = ["2001:cafe:42::/64" "10.42.0.0/24"]`, `ips = ["2a02:a313:43e4:7080::7dc5" "192.168.0.10"]`, `externalIPs = ["2a02:a313:43e4:7080::7dc5"]`, `node-name = "m00nsrv"`, `gracefulNodeShutdown.enable = false`.
- OIDC auth config built via `pkgs.formats.yaml` from issuer `https://idm.m00nlit.dev/oauth2/openid/kubernetes`, audience `kubernetes`, with `name → oidc:` and `groups → oidc:` claim mappings.
- `service-account-issuer = "https://k8s.m00nlit.dev"`, JWKS URI suffix `/openid/v1/jwks`.
- Feature gates: `MutatingAdmissionPolicy=true`; runtime-config `admissionregistration.k8s.io/v1beta1=true`.
- Anonymous paths: `/livez /readyz /healthz /.well-known/openid-configuration /openid/v1/jwks`.
- Kubelet args: `make-iptables-util-chains=false`, `max-pods=250`; extra kubelet config `memorySwap.swapBehavior = LimitedSwap`, `imageMaximumGCAge = "12h"`, `cgroupDriver = "systemd"`, feature gate `ImageVolume = true`.
- `firewall.enable = lib.mkForce false`.
- cri-o integration: package built from `inputs.stable` (nixos-25.11) with ZFS extension when supported, `extraPackages = cri-o.extraPackages ++ zfs.package`, runtimes `nvidia` (nvidia-container-toolkit) and `kata` (kata-runtime), `plugin_dirs = ["/opt/cni/bin"]`, `hooks_dir = ["/usr/share/containers/oci/hooks.d"]`, `image_volumes = "mkdir"`, `short_name_mode = false`. Sets `environment.etc."nvidia-container-runtime/config.toml".text` to use `${pkgs.crun}/bin/crun`. `virtualisation.cri-o.storageDriver = "zfs"`.
- `services.seatd.enable = true`, `services.openiscsi.enable = true`.

### `den.aspects.hardware.ssh-tpm-agent` (`modules/aspects/hardware/ssh-tpm-agent.nix`)

Ported from nixold `legacy/modules/hardware/ssh-tpm-agent.nix`:

- `security.tpm2.enable = true`, `tctiEnvironment.enable = true`.
- Default `services.sshTpmAgent.enable = true` (overridden to `false` by the SSH aspect for this host).

### `den.aspects.hosts.ganymede` (`modules/aspects/hosts/ganymede.nix`)

```nix
{ den, inputs, config, lib, pkgs, ... }:
{
  __findFile ? __findFile,
  flake-file,
  ...
}:
{
  includes = [
    <boot/secureboot>
    <system/server>
    <system/zfs>
    <system/k3s>
    <hardware/ssh-tpm-agent>
  ];

  den.aspects.ganymede = { ... }: {
    imports = [
      "${inputs.self}/hosts/${config.networking.hostName}/disk-config.nix"
      (flake-file.inputs "stable.nixosModules.systemd")
    ];

    networking.hostName = "ganymede";
    system.stateVersion = "24.11";
    networking.hostId = lib.mkForce "8504e2ee";

    networking.useDHCP = false;
    systemd.network.links."10-lan" = {
      matchConfig.MACAddress = "9c:6b:00:08:bb:03";
      linkConfig.Name = "lan0";
    };
    systemd.network.networks."30-lan" = {
      matchConfig.Name = "lan0";
      networkConfig = {
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = false;
        MulticastDNS = true;
      };
      address = [
        "192.168.0.10/24"
        "2a02:a313:43e4:7080::7dc5/64"
        "fd42:78a5:2c09::7dc5/64"
      ];
      route = [
        { Gateway = "192.168.0.1"; }
        { Destination = "::/0"; Gateway = "fe80::1%lan0"; }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 25565 443 80 2049 ];
    networking.firewall.allowedUDPPorts = [ 25565 443 2049 ];

    services.radvd = {
      enable = true;
      interfaces."lan0" = {
        IgnoreIfMissing = true;
        AdvSendAdvert = true;
        MaxRtrAdvInterval = 100;
        MinRtrAdvInterval = 30;
        prefixes = [
          { Prefix = "2a02:a313:43e4:7080::/64"; AdvOnLink = true; }
          { Prefix = "fd42:78a5:2c09::/64"; AdvOnLink = true; }
        ];
        RDNSS = [ "fd42:78a5:2c09::53" ];
      };
    };

    networking.nftables.enable = true;

    services.nfs.server.enable = true;
    services.openiscsi = {
      enable = true;
      name = "iqn.2016-04.com.open-iscsi:bd68ae22efed";
    };

    services.resolved.enable = false;
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "::1" ];
          do-ip4 = false;
          do-ip6 = true;
          do-tcp = true;
          do-udp = true;
          harden-glue = true;
          harden-dnssec-stripped = true;
          prefetch = true;
          edns-buffer-size = 1232;
          hide-identity = true;
          hide-version = true;
          prefer-ip6 = true;
        };
        forward-zone = [
          { name = "."; forward-tls-upstream = true; forwarders = [
            { ip = "2620:fe::fe"; host = "dns.quad9.net"; }
            { ip = "2620:fe::9";  host = "dns.quad9.net"; }
            { ip = "2606:4700:4700::1111"; host = "cloudflare-dns.com"; }
            { ip = "2606:4700:4700::1001"; host = "cloudflare-dns.com"; }
          ]; }
          { name = "tail096cd8.ts.net."; forwarders = [ "100.100.100.100" ]; }
        ];
      };
    };

    services.tailscale = {
      enable = true;
      advertiseRoutes = [ advertisedRoutes ];
      extraSetFlags = [
        "--accept-routes"
      ];
    };
    environment.etc."tailscale-net-tweak.service".source = pkgs.writeText "tailscale-net-tweak.service" ''
      [Unit]
      Description=Enable Tailscale UDP GRO forwarding
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      ExecStart=/bin/sh -c '\
        for d in /sys/class/net/*/device; do \
          iface=$(basename "$(dirname "$d")"); \
          ip route show default | awk -v i="$iface" "{exit (\$5 == i) ? 0 : 1}" || continue; \
          ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off || true; \
        done'

      [Install]
      WantedBy=multi-user.target
    '';
    systemd.services.tailscale-net-tweak = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig.Type = "oneshot";
      script = builtins.readFile config.environment.etc."tailscale-net-tweak.service".source;
    };

    boot.kernel.sysctl."net.ipv4.ip_local_reserved_ports" = "30000-32767";
    boot.kernelModules = [ "ip6_tables" "ip6table_mangle" "ip6table_raw" "ip6table_filter" ];

    hardware.nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "nvidia-x11" "nvidia-kernel-modules" ];

    time.timeZone = "Europe/Warsaw";
    console.keyMap = "pl";

    boot.initrd.systemd.enable = true;
    fileSystems."/efi".device = "/dev/disk/by-id/nvme-Micron_7450_MTFDKBA960TFR_24334AA93946-part1";
  };
}
```

The host aspect also sets `services.openssh.openFirewall = true` to keep the original semantics; firewall port lists are kept inert per the strict-fidelity decision.

## Inputs

Reuse the existing flake inputs (`disko`, `disko-zfs`, `lanzaboote`, `sops-nix`, `stable`). No new inputs are introduced.

## Secrets

- `secrets/k3s.yaml` (already in repo root) provides `k3s/token` for `den.aspects.system.k3s`.
- `secrets/authorized_keys` (already in repo root) provides root's authorized keys.
- `hosts/ganymede/secrets/default.yaml` is not required: the sops aspect already wraps its import in `lib.mkIf (builtins.pathExists …)`.
- The sops `.sops.yaml` rule for `systems/.../ganymede/secrets/...` translates to `hosts/.../ganymede/secrets/...`; update only if a future secret is added.

## Migration hazards noted, not fixed (per strict-fidelity)

These items were flagged in the exploration of nixold and are deliberately preserved as-is:

1. `networking.hostId = lib.mkForce "8504e2ee"` keeps ZFS pools importable on this hardware; removing the override requires regenerating the seed-derived hostId.
2. `networking.firewall.enable = lib.mkForce false` makes the declared `allowedTCPPorts`/`allowedUDPPorts` inert.
3. The `k3s` `node-name = "m00nsrv"` does not match `networking.hostName = "ganymede"`.
4. `system.stateVersion = "24.11"` differs from the repo default (`26.11`).
5. Hard-coded hostname references in `home/m00n/dev.nix` (`ganymede:6443`) and `home/m00n/ssh.nix` (`Host = "ganymede"`) remain decoupled from `networking.hostName`.

## Out of scope

- `users.m00n` Home Manager wiring for ganymede.
- Behavior cleanups listed above.
- Hardware regeneration (new `facter.json`, new disk identifiers, new LUKS UUID).
- Adding beacon (a second server host).
- Removing unused `modules/` tree under nixold or elsewhere.

## Success criteria

1. `nix flake check` reports a `ganymede` system that evaluates without errors.
2. `nixos-rebuild build --flake .#ganymede` produces a derivation whose closure references all expected aspects and the copied `disk-config.nix`.
3. The resulting configuration matches the nixold ganymede behavior on every option listed in the "Resulting layout" / "Aspect responsibilities" sections.
4. No existing host (`tide`, `kepler`, `ember`) changes its evaluation result.
