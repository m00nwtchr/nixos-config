# MIGRATION: porting `~/nixos-config` to the den pattern

## Summary

The `~/nixos-config` repo (snowfall-lib based NixOS configuration
for the `tide`, `ember`, `kepler`, `ganymede`, and `beacon` hosts)
has been ported to the `~/nixnew` repo (den aspect pattern,
flake-parts based). **Only `tide` and the `m00n` user/home for
tide are ported**; the other hosts are out of scope for this
migration.

## What works

`nix run .#tide -- build` evaluates and builds a NixOS
configuration for the `tide` host. The full den-aspect
configuration graph is exercised:

* Boot aspect (EFI / systemd-boot / lanzaboote secureboot)
* Base system aspect (nix settings, apparmor, networkd, zramSwap,
  nameservers, basic packages, tailscale, resolved)
* `system/desktop`, `system/splash`, `system/sops`, `system/podman`,
  `system/vms`, `system/gaming`, `system/rfkill-wlan0` sub-aspects
* `hardware/facter` (loads `hosts/tide/facter.json`)
* `amdgpuDynamicVram` (Framework 16 dynamic VRAM tuning)
* `hosts/tide` (Framework 16 / ROCm / memlock / ollama-vulkan /
  wireplumber / bridges)
* User `m00n` (sops secrets, openssh keys, primary-user + zsh
  shell batteries)
* Home sub-aspects for m00n: `env`, `dev`, `shell`, `rust`,
  `containers`, `ssh`, `gpg`, `rclone`, `autostart`, `wayland`,
  `default` (librewolf, mpv, packages, services), `sway`,
  `wallust`, `dunst`, `waybar` (plus the thin `modules-dotfiles`
  and `modules-uwsm` stubs)

The NixOS build (50.7 GiB → 44.3 GiB) succeeds after pulling
down the full set of derivations.

## Deliberate deviations from source

### Aspect wiring

The den aspect system has a recursive type-checker that
infinite-loops when aspects have cross-references in their
declarations. The aspect files in `modules/aspects/` are written
as plain top-level aspects (e.g. `den.aspects.boot`,
`den.aspects.system.podman`, `den.aspects.home.dev`). The host
aspect in `modules/aspects/hosts/tide.nix` references them via
**direct attribute access** (`den.aspects.boot`, etc.) rather
than angle-bracket syntax (`<boot>`). This avoids the `<x/y>`
resolution rules and namespace-registration dance.

The two den namespaces that ARE registered (in `dendritic.nix`)
are `hardware` (for the existing `facter.nix` pattern) and
`users` (matches the `users/m00n.nix` sub-aspect name).

### Option path renames (den-native)

Source used `m00nlit.*` namespace options. The den port uses
plain den-managed options:

| Source                                | Port                              |
|---------------------------------------|-----------------------------------|
| `m00nlit.ppd-auto.*`                  | `den.aspects.ppd-auto.*` (kept as `den.aspects.ppd-auto` via `<hardware/ppd-auto>` angle bracket) |
| `m00nlit.hardware.facter.detected.*`  | `facter.detected.*` (via `hardware/facter` namespace) |
| `m00nlit.kubeconfig.*`                | Not ported; `home/dev.nix` writes a stub kubeconfig file |
| `dotfiles.mutable` (hm option)        | Removed — option no longer exists in current home-manager |
| `dotfiles.path` (hm option)           | Removed — option no longer exists in current home-manager |

### `pkgsStable` (nixos-25.11) — DEFERRED

The source repo's top-level `flake.nix` injects a `pkgsStable`
from `inputs.stable` (nixos-25.11) into both nixos and
homeManager via `_module.args.pkgsStable = import inputs.stable …`.
The den port does NOT replicate this — the only consumer in the
source (`homes/.../m00n/default.nix:130` — `package = pkgsStable.librewolf;`)
is commented out, and no other code references `pkgsStable`.

**To re-enable later**: add a `stable.url = "github:NixOS/nixpkgs/nixos-25.11";`
input in `modules/dendritic.nix`, create a `den.aspects.stable` aspect
in `modules/aspects/system/stable.nix` that injects `_module.args.pkgsStable`
into both `nixos` and `homeManager` class args (replacing
`pkgs` with `pkgsStable` where pinned), include it from
`den.aspects.tide` and `den.aspects.m00n`, and re-run.

### `osConfig` in home aspects

The source's `homes/.../m00n/shell.nix` reads
`osConfig.sops.secrets.atuin_key.path` (an `osConfig` module
arg). In den, **home aspects do not receive `osConfig` as an
argument** — the home-vs-host boundary is enforced by the
framework. The den port hardcodes the atuin `key_path` and
`session_path` to `${config.xdg.stateHome}/atuin/key` and
`${config.xdg.stateHome}/atuin/session` (the canonical home-manager
defaults). The actual atuin key still lives at `secrets/atuin_key.txt`
and the session at `secrets/atuin/session` (referenced from the
`m00n` user aspect's `provides.to-hosts.nixos`).

### Lanceboot v0.4.3 + measuredBoot

The source's `boot.lanzaboote.measuredBoot = { enable = true; pcrs = [0 1 2 3 4 7]; }`
references options that have been removed in current
lanzaboote. The den port has the block **commented out** (the
hardware secret-key secureboot setup is still applied).

### Bitwarden-desktop

The user removed the `bitwarden-desktop` line from
`modules/aspects/system/desktop.nix` (a commit by
`m00nwtchr <m00n@naktis.eu>` to keep the build working without
the package). It is currently commented out.

### `lanzaboote` broken against current nixpkgs

The lanzaboote input in `flake.nix` is the latest from
`github:nix-community/lanzaboote` (no v0.4.3 pin in the
generated flake.nix). v0.4.3 fails against current nixpkgs
because of removed options (`boot.bootspec.enable` was removed
upstream). The den port leaves the `inputs.lanzaboote` reference
in `modules/aspects/boot.nix` but the `measuredBoot` block is
commented out. The build of `nix run .#tide` succeeds.

### Sops secrets file paths

The source repo's `flake.nix:101-105` injects
`pkgsStable` via `_module.args`, and the legacy `sops-nix.nix`
module's `defaultSopsFile` uses `${inputs.self}/systems/...`
paths. The den port's `modules/aspects/system/sops.nix` uses
`${inputs.self}/hosts/${hostName}/secrets/default.yaml`
(matching the new data-dir layout under `~/nixnew/hosts/tide/secrets/`).

### Disk layout (disko)

The source's `disko` config is in
`systems/x86_64-linux/tide/disk-config.nix` (btrfs-on-LUKS with
hibernation resume). The den port does NOT yet include the
disko config — `fileSystems."/"` is set to a placeholder
(`/dev/fake`) so the system builds. The disko aspect is TODO.

## What's TODO (in priority order)

1. **Disko aspect** (`modules/aspects/disk.nix`): port the
   btrfs-on-LUKS config from
   `~/nixos-config/systems/x86_64-linux/tide/disk-config.nix`.
2. **`pkgsStable` aspect** (if/when needed): see "deferred" above.
3. **`kubeconfig` module** (`modules/home/kubeconfig/default.nix` in
   source): currently stubbed in `home/dev.nix`.
4. **`easyeffects` preset** (`modules/home/easyeffects/default.nix` in
   source): per-host aspect for `hosts/tide/easyeffects/*.json`.
5. **Lanzaboote `measuredBoot` block**: currently commented out
   (waiting for lanzaboote to support current nixpkgs).
6. **Bitwarden-desktop**: currently commented out.
7. **Source overlays** (`~/nixos-config/overlays/`): not ported.
   Tide doesn't use them, so this is fine for now.

## File layout (post-port)

```
~/nixnew/
├── flake.nix                            (auto-generated by nix run .#write-flake)
├── .sops.yaml                           (copied from source)
├── treefmt.toml                         (copied)
├── renovate.json5                       (copied)
├── .gitattributes                       (copied)
├── secrets/                             (copied: atuin_key.txt, authorized_keys,
│                                          k3s.yaml, proton.yaml)
│
├── hosts/tide/                          (data dir for tide)
│   ├── facter.json                      (already there)
│   ├── host-seed
│   ├── secrets/default.yaml            (sops-encrypted)
│   └── easyeffects/amesb fw16 EE profile.json
│
├── home/m00n/                           (home data dir for m00n)
│   ├── bin/uwsm-game.sh                 (copied)
│   ├── sway/{config, default.nix, icc/}
│   ├── wallust/{default.nix, wallust.toml, templates/}
│   ├── dunst/default.nix
│   └── waybar/{default.nix, layout.nix, modules.nix, custom.nix, style.css}
│
└── modules/
    ├── apps.nix                         (REMOVED — diff harness dropped)
    ├── defaults.nix                     (stateVersion, allowUnfree, classes)
    ├── dendritic.nix                    (flake-file inputs, den namespaces)
    ├── hosts.nix                        (den.hosts.x86_64-linux.tide.users.m00n)
    ├── nh.nix                           (kept as-is)
    ├── vm.nix                           (kept as-is)
    │
    └── aspects/
        ├── boot.nix                     (den.aspects.boot, +secureboot sub-aspect)
        │
        ├── hosts/
        │   └── tide.nix                 (den.aspects.tide + den.aspects.hosts.tide)
        │
        ├── users/
        │   └── m00n.nix                 (den.aspects.m00n + provides.to-hosts.nixos)
        │
        ├── system/                      (sub-aspects of system)
        │   ├── system.nix               (den.aspects.system)
        │   ├── desktop.nix              (den.aspects.system.desktop)
        │   ├── splash.nix               (den.aspects.system.splash)
        │   ├── sops.nix                 (den.aspects.system.sops)
        │   ├── podman.nix               (den.aspects.system.podman)
        │   ├── vms.nix                  (den.aspects.system.vms)
        │   ├── gaming.nix               (den.aspects.system.gaming)
        │   └── rfkill-wlan0.nix         (den.aspects.system.rfkill-wlan0)
        │
        ├── hardware/                    (existing; only facter + amdgpu used)
        │   ├── facter.nix               (existing; loads facter.json)
        │   └── amdgpu.nix               (existing; defines dynamicVram + auto-initrd)
        │
        └── home/                        (15 sub-aspects of home)
            ├── autostart.nix             (den.aspects.home.autostart)
            ├── containers.nix           (den.aspects.home.containers)
            ├── default.nix              (den.aspects.home.default — main m00n)
            ├── dev.nix                   (den.aspects.home.dev)
            ├── dunst.nix                 (den.aspects.home.dunst)
            ├── env.nix                   (den.aspects.home.env)
            ├── gpg.nix                   (den.aspects.home.gpg)
            ├── modules-dotfiles.nix      (den.aspects.home.modules-dotfiles, stub)
            ├── modules-uwsm.nix          (den.aspects.home.modules-uwsm, stub)
            ├── rclone.nix                (den.aspects.home.rclone)
            ├── rust.nix                  (den.aspects.home.rust)
            ├── shell.nix                 (den.aspects.home.shell)
            ├── ssh.nix                   (den.aspects.home.ssh)
            ├── sway.nix                  (den.aspects.home.sway)
            ├── wallust.nix               (den.aspects.home.wallust)
            ├── waybar.nix                (den.aspects.home.waybar)
            └── wayland.nix               (den.aspects.home.wayland)
```

## Verification

```bash
nix --extra-experimental-features 'nix-command flakes' \
  eval /home/m00n/nixnew#nixosConfigurations.tide.config.system.stateVersion
# → "26.05"

nix --extra-experimental-features 'nix-command flakes' run .#tide -- build
# → builds nixos-system-tide-26.05.<rev>
```

## Out of scope

* Other hosts in `~/nixos-config` (ember, kepler, ganymede, beacon)
* The `k3s` system module (ganymede-specific)
* The `clamav`, `greeter` modules (commented out in source)
* The `~/nixos-config/overlays/` (jool, pywalfox, safeeyes)
* `lanzaboote` v0.4.3 measuredBoot — waiting on upstream fix
* `pkgsStable` — see deferred section above
