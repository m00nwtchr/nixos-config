# MIGRATION: porting `~/nixos-config` to the den pattern

## Summary

The `~/nixos-config` repo (snowfall-lib based NixOS configuration
for the `tide`, `ember`, `kepler`, `ganymede`, and `beacon` hosts)
has been ported to the `~/nixnew` repo (den aspect pattern,
flake-parts based). **Only `tide` and the `m00n` user/home for
tide are ported**; the other hosts are out of scope for this
migration.

The port is **buildable and evaluated** for tide: the build
succeeds and all source aspects (modulo the deferred/commented
items listed below) are active in the aspect graph.

**One intentional exclusion**: `den.aspects.hosts.tide-disk` is
**defined** in `modules/aspects/hosts/tide.nix` but is
**commented out** from `den.aspects.tide.includes` (line 228).
This means no disko layout is applied; the build succeeds
without any `fileSystems."/"` declaration. To enable the
btrfs-on-LUKS layout, uncomment that line. See the "Disko
btrfs-on-LUKS" section below for details.

## What works

`nix run .#tide -- build` evaluates and builds a NixOS
configuration for the `tide` host. The full den-aspect
configuration graph is exercised:

### Host (NixOS) aspects

* **Boot**: EFI / systemd-boot / lanzaboote secureboot
* **System** sub-aspects: `system`, `desktop`, `splash`, `sops`,
  `podman`, `vms`, `gaming`, `rfkill-wlan0`, `autologin` (TTY1
  autologin as m00n), `wayland` (NixOS-side: xdg desktop portal,
  fonts, thunar, gvfs, udisks2, tumbler), `wayland-sway`
  (NixOS-side: programs.uwsm, programs.sway, xdg.portal.wlr),
  `home-manager` (useGlobalPkgs, useUserPackages,
  backupFileExtension)

  NTP: tide (desktop) uses NixOS's default `services.timesyncd`
  (systemd-timesyncd), NOT chrony. The source's `chrony.nix` is
  only used by the `server.nix` profile (ganymede/other servers).
  Don't add a chrony aspect for tide.

  openssh, sshTpmAgent, btrfs, zfs: tide does NOT have any of
  these. The source's tide default.nix has
  `# "${inputs.self}/legacy/modules/hardware/zfs.nix"` commented
  out, and does not import `ssh.nix` (which contains
  openssh+sshTpmAgent) or `hardware/btrfs.nix`. Don't add a
  `system/ssh.nix`, `hardware/zfs.nix`, `hardware/btrfs.nix`, or
  `hardware/ssh-tpm-agent.nix` aspect for tide. The openssh /
  sshTpmAgent packages may still appear in the closure as
  transitive deps of other things (e.g. `home/ssh.nix` adds
  ssh-tpm-agent as a user pkg), but the SERVICES are not enabled.
* **Hardware** sub-aspects:
  * `facter` (loads `hosts/tide/facter.json`; derives
    `wireless`, `isLaptop`, `isDesktop`, `nvidia` detected flags)
  * `amdgpuDynamicVram` (Framework 16 dynamic VRAM tuning)
  * `wireless` (iwd, regdom, systemd-networkd wifi, bluetooth)
  * `laptop` (ac/battery targets, smt, powertop, upower,
    networkd-dispatcher for tailscale, logind lid handling)
  * `nvidia` (conditional; not active on tide)
  * `btrfs` (NOT active for tide; see System sub-aspects note)
  * `zfs` (NOT active for tide; see System sub-aspects note)
  * `ssh-tpm` (NOT active for tide; see System sub-aspects note)
  * `ppd-auto` (auto-switching power-profiles-daemon based on
    battery threshold; activated via `laptop.nix`)
* **Hosts** sub-aspects:
  * `tide` (Framework 16 / ROCm / ollama-vulkan / wireplumber /
    bridges / memlock / `boot.zfs.*` / `boot.extraModprobeConfig`
    blacklist sp5100_tco / nixos-hardware
    framework-16-amd-ai-300-series import)
  * `tide-disk` (disko btrfs-on-luks config) — **DEFINED BUT
    COMMENTED OUT** from `den.aspects.tide.includes`. The aspect
    exists in `modules/aspects/hosts/tide.nix` and is fully
    ported, but is not applied to the tide build. See the
    "Disko btrfs-on-LUKS" section for the rationale.

### User / home aspects (m00n)

* **User `m00n`**: sops secrets, openssh keys, primary-user +
  zsh shell batteries, atuin/proton secrets, autouid/gid
* **Home** sub-aspects (16 active + 1 stub):
  * `env`, `dev` (helix+langservers, git, uv, dev tooling;
    also owns the `alejandra` flake-file input)
  * `shell`, `rust`, `containers`, `ssh`, `gpg`, `rclone`
  * `autostart`, `wayland` (wl-clipboard, bemenu, grim, slurp,
    swaylock-effects, wallust, fonts, alacritty, fuzzel, eww,
    swayidle, gammastep, cliphist, mpris, plus
    `bin/uwsm-game.sh` install)
  * `default` (home.packages, xdg.mimeApps, librewolf, mpv,
    syncthing, activitywatch, Yubico u2f_keys)
  * `sway`, `wallust`, `dunst`, `waybar` (with `imports` of
    `home/m00n/waybar/{modules,custom,layout}.nix`)
  * `uwsm` (programs.uwsm.environment env vars, `app2unit`,
    `uwsm-game`/`uwsm-shell` packages, xdg-utils override,
    `GAMEMODERUNEXEC`, `programs.zsh.profileExtra = 'exec
    uwsm start default'`, `programs.alacritty.settings.terminal.shell`,
    systemd user service slice assignments for swayidle/waybar/
    syncthingtray/cliphist/cliphist-images/gammastep)
  * `uwsm-modules` (defines `programs.uwsm.environment` option
    type, writes `xdg.configFile."uwsm/env"`)
  * `easyeffects` (per-host preset loader for
    `hosts/tide/easyeffects/*.json`; auto-selects single preset)
  * `kubeconfig` (defines `m00n.kubeconfig.{enable,clusters,contexts,users,config}`
    options; renders `xdg.configFile."kube/config"` as YAML)
  * `modules-dotfiles` (stub)

The NixOS build (50.7 GiB → ~45-50 GiB, depending on nixpkgs
revision) succeeds. The exact SIZE depends on the nixpkgs
revision pulled by the lock file; the comparison against the
running system is in the build output (`SIZE:` / `DIFF:` lines
at the end of `nix run .#tide -- build`).

## Spot-check results

```
# nix run .#tide -- build
SIZE: 50.7 GiB -> 49.7 GiB  (DIFF: -1.05 GiB)
# (the running system uses 26.11.20260606; the port uses 26.11.20260611;
# SIZE/DIFF numbers track this directly)

# === Boot / hardware (den.aspects.boot + den.aspects.hosts.tide) ===
hardware.amdgpu.dynamicVram.enable          = true
hardware.amdgpu.initrd.enable               = true
hardware.amdgpu.opencl.enable               = true
boot.zfs.unsafeAllowHibernation            = true
boot.zfs.forceImportRoot                   = false
boot.extraModprobeConfig                   = "blacklist sp5100_tco\n"
boot.loader.systemd-boot.enable            = true
boot.loader.grub.enable                    = false   (force-false in boot.nix)
boot.lanzaboote.enable                     = true    (secureboot sub-aspect)
boot.supportedFilesystems                  = [ "btrfs" "ntfs" "vfat" "zfs" ]
hardware.facter.detected.isLaptop          = true
hardware.facter.detected.wireless          = true
hardware.facter.detected.nvidia            = false
hardware.facter.detected.isDesktop         = false
networking.hostId                          = "..."  (NOT set; zfs aspect not active)

# === Tide host (den.aspects.hosts.tide) ===
services.ollama.enable                     = true
services.ollama.package.pname              = "ollama"
services.tailscale.enable                  = true
hardware.bluetooth.powerOnBoot             = false   (laptop: !isLaptop)
services.m00n.ppd-auto.enable              = true    (laptop activates)
services.power-profiles-daemon.enable      = true
systemd.services."powerprofile-set@balanced".enable
                                            = true
systemd.services."beesd@root".enable       = true    (btrfs aspect, on laptop)
security.pam.loginLimits                   contains memlock=unlimited for m00n
networking.bridges                          = { br0 = { interfaces = [ "wlan0" ]; }; }

# === Storage aspects (btrfs wins over zfs at prio 998) ===
services.btrfs.autoScrub.enable            = false   (btrfs aspect NOT active for tide)
services.zfs.autoScrub.enable              = false   (zfs aspect NOT active for tide)
services.getty.autologinUser              = "m00n"  (autologin aspect)
services.openssh.enable                   = false   (tide source doesn't enable openssh)
services.sshTpmAgent.enable               = false   (tide source doesn't enable sshTpmAgent)
programs.uwsm.enable                      = true    (wayland-sway aspect)
programs.sway.enable                      = true
xdg.portal.wlr.enable                    = true
services.xserver.desktopManager.runXdgAutostartIfNone
                                            = false  (wayland aspect)
fonts.packages                            contains dejavu, noto-fonts, etc.
home-manager.useGlobalPkgs                = true
home-manager.useUserPackages              = true
virtualisation.containers.storage.settings.storage.driver
                                            = "btrfs"
zramSwap.enable                            = true    (system aspect)
boot.kernel.sysctl."vm.swappiness"         = 180     (system aspect)

# === System aspects (den.aspects.system.*) ===
programs.obs-studio.enable                 = true
programs.ccache.enable                     = true
programs.appimage.enable                   = true
services.logrotate.checkConfig             = false
services.resolved.enable                   = true
security.tpm2.enable                       = true
security.pam.u2f.enable                    = true
services.pipewire.enable                   = true
virtualisation.containers.enable           = true
i18n.defaultLocale                         = "en_GB.UTF-8"

# === User (den.aspects.m00n, NixOS side) ===
users.users.m00n.isNormalUser              = true
users.users.m00n.uid                       = 1000
users.users.m00n.hashedPasswordFile        = "...secrets/passwords/m00n"  (sops)
sops.secrets.atuin_key                     defined (format=binary, owner=m00n)
sops.secrets."proton/password"            defined
sops.secrets."proton/otp_secret_key"      defined

# === Home (nix eval .#homeConfigurations.m00n.config.X) ===
home.username                              = "m00n"
home.homeDirectory                         = "/home/m00n"
home.stateVersion                          = "26.05"
home.packages                             contains htop, helix, wallust, p10k.zsh,
                                            arduino-ide, zsh-powerlevel10k
programs.helix.enable                      = true
programs.zsh.enable                        = true
programs.zsh.initContent                   sources p10k.zsh + zsh-powerlevel10k
programs.zsh.siteFunctions                  = { kpatch_all_ns; _kpatch_all_ns; }
programs.zsh.profileExtra                  contains "uwsm start"
programs.direnv.enable                    = true
programs.atuin.enable                      = true
programs.rust-rover                        = true    (rust.nix aspect)
home.file.".cargo/config.toml"            has linker=clang + mold
programs.atuin.enable                      = true
programs.alacritty.settings.terminal.shell = ".../uwsm-shell/bin/uwsm-shell"
programs.fuzzel.enable                     = true
programs.eww.enable                        = true
services.syncthing.enable                  = true
services.activitywatch.enable              = false
services.gpg-agent.enable                  = true
services.ssh-agent.enable                  = true
services.swayidle.enable                   = true
services.gammastep.enable                  = true
services.cliphist.enable                   = true
services.mpris-proxy.enable                = true
services.easyeffects.enable                = true
services.easyeffects.extraPresets          contains "amesb fw16 EE profile"
                                              (full preset data from
                                               hosts/tide/easyeffects/*.json)
xdg.configFile."sway/config".source       = ".../home/m00n/sway/config"
xdg.configFile."uwsm/env".text             = "export WLR_RENDERER=..."
                                              (exportAll of programs.uwsm.environment)
xdg.configFile."wallust/wallust.toml".source
                                            = ".../home/m00n/wallust/wallust.toml"
home.file.".local/share/uwsm-game.sh".executable
                                            = true
home.sessionVariables.GAMEMODERUNEXEC      = "uwsm-game"
fonts.fontconfig.enable                    = true
systemd.user.services.swayidle.Service.Slice
                                            = "background-graphical.slice"
systemd.user.services.waybar.Service.Slice
                                            = "app-graphical.slice"
```

## Den-specific patterns used

### `__findFile` for angle-bracket resolution

All aspect files declare `__findFile ? __findFile,` in their
argument list. This is required for the den aspect system to
resolve `<x/y>` angle-bracket references (e.g. `<boot>`,
`<system/sops>`, `<hardware/facter>`).

### `inputs.self` for repo-root paths

Paths to data files in the repo use `${inputs.self}/...` rather
than long `../../../` chains. `./foo.nix` (single dot) paths
relative to the aspect file are kept as-is.

Examples:
* `modules/aspects/hosts/tide.nix` (which uses
  `inputs.disko.nixosModules.disko` and
  `inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series`)
* `modules/aspects/hardware/zfs.nix`:
  `"${inputs.self}/hosts/${config.networking.hostName}/host-seed"`
* `modules/aspects/system/sops.nix`:
  `"${inputs.self}/hosts/${config.networking.hostName}/secrets/default.yaml"`
* `modules/aspects/home/easyeffects.nix`:
  `"${inputs.self}/hosts/tide/easyeffects"`
* `modules/aspects/home/uwsm.nix`:
  `builtins.readFile ../../../home/m00n/bin/uwsm-game.sh`
  (kept as `./`-relative; the home/ data dir is one level up
  from the aspects dir; could be `${inputs.self}/home/m00n/bin/uwsm-game.sh`)

### Flake-file input co-location

Per the user's rule, each flake-file input is declared at the
module/aspect that imports or uses it — not centrally in
`dendritic.nix`. The dendritic file only contains the framework
meta-inputs (`den`, `flake-file`) plus the shared
`home-manager`.

| Input              | Co-located in (file)                                 |
|--------------------|------------------------------------------------------|
| `den`              | `modules/dendritic.nix` (meta)                       |
| `flake-file`       | `modules/dendritic.nix` (meta)                       |
| `home-manager`     | `modules/dendritic.nix` (used by many home aspects)  |
| `lanzaboote`       | `modules/aspects/boot.nix`                           |
| `sops-nix`         | `modules/aspects/system/sops.nix`                    |
| `nixos-hardware`   | `modules/aspects/hosts/tide.nix`                     |
| `disko`            | `modules/aspects/hosts/tide.nix`                     |
| `disko-zfs`        | `modules/aspects/hosts/tide.nix`                     |
| `alejandra`        | `modules/aspects/home/dev.nix` (formatter for dev)   |

Each file declares it as `flake-file.inputs.<name> = { url = "..."; ... };`
at the top level. The den framework aggregates these into the
final `flake.nix` via `nix run .#write-flake`.

### `m00n` namespace for per-user options

The user's own options (defined in aspects) use the `m00n`
namespace as a top-level sub-namespace in the nixos/homeManager
class option space. This is den-native (replaces the source's
`m00nlit.*` namespace):

| Aspect        | Option path                            | Pattern                          |
|---------------|----------------------------------------|----------------------------------|
| `ppd-auto`    | `services.m00n.ppd-auto.{enable,...}`  | in nixos class                   |
| `kubeconfig`  | `m00n.kubeconfig.{enable,...}`         | in homeManager class             |
| `easyeffects` | no options (just services.easyeffects) | n/a                              |

Aspect `nixos`/`homeManager` functions read live values via
`config.<option-path>` (e.g. `config.services.m00n.ppd-auto`)
and bind to a local `cfg` for use in `lib.mkIf cfg.enable` and
`lib.mkIf cfg.X` patterns.

### Class function arg pattern

For aspects whose `nixos` (or `homeManager`) class function uses
`pkgs` (e.g. for `pkgs.writeShellScriptBin`, `pkgs.formats.yaml`,
`pkgs.linuxPackages`), the class function MUST declare `pkgs`
in its args:

```nix
den.aspects.<name> = {
  nixos = {config, lib, pkgs, ...}: {
    # ...use pkgs.foo.bar, config.X, lib.X...
  };
};
```

If `pkgs` is not in the class function args, evaluation fails
with `attribute 'pkgs' missing` (the aspect is treated as a
NixOS module and `pkgs` is looked up in `_module.args.pkgs`,
which isn't available in this context).

Files that use this pattern:
* `modules/aspects/hardware/laptop.nix`
* `modules/aspects/hardware/ppd-auto.nix`
* `modules/aspects/hardware/zfs.nix`
* `modules/aspects/home/uwsm.nix`

Files that don't use `pkgs` in the class function:
* `modules/aspects/hardware/{wireless,nvidia,btrfs}.nix`
* `modules/aspects/hardware/facter.nix` (only sets options)

### Sub-aspect composition (`includes = [config.secureboot]`)

`modules/aspects/boot.nix` shows how to split a parent aspect
into a parent + sub-aspect that the parent transitively pulls
in:

```nix
den.aspects.boot = {config, ...}: {
  includes = [config.secureboot];
  nixos = { ... };
  secureboot.nixos = { ... };   # sub-aspect config
};
```

The `includes = [config.secureboot]` reference is a den pattern:
when a parent aspect has a sub-aspect (declared at the same
level as `nixos`), den routes the sub-aspect to `config.<sub-aspect-name>`
so it can be transitively included. The `secureboot` sub-aspect
is what configures Lanzaboote (`boot.lanzaboote.enable = true`)
and adds `pkgs.sbctl` to `environment.systemPackages`.

This is the den-native way to express "include this extra config
when the parent is included", without needing angle-bracket
references to non-existent aspects.

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
`m00n.*` (or the aspect name directly) as the per-user/feature
namespace:

| Source                                | Port                                          |
|---------------------------------------|-----------------------------------------------|
| `m00nlit.ppd-auto.*`                  | `services.m00n.ppd-auto.*`                     |
| `m00nlit.hardware.facter.detected.*`  | `hardware.facter.detected.*` (via the `facter` aspect, not a `m00nlit` namespace) |
| `m00nlit.kubeconfig.*`                | `m00n.kubeconfig.*`                            |
| `m00nlit.laptop.enable`               | `den.aspects.laptop.enable` (aspect option)    |
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

### `nvidia` branch in uwsm env (tide is AMD-only)

The source's `home/uwsm.nix` had:
```nix
programs.uwsm.environment =
  { ... } // lib.optionalAttrs osConfig.${namespace}.hardware.facter.detected.nvidia {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };
```
The den port can't access `osConfig` in a home aspect (see
above). The nvidia env vars are commented out with the original
code as a comment block for future restoration when running on
a nvidia host. For tide (AMD-only), this has no effect.

### Lanzaboote v0.4.3 + measuredBoot

The source's `boot.lanzaboote.measuredBoot = { enable = true; pcrs = [0 1 2 3 4 7]; }`
references options that have been removed in current
lanzaboote. The den port has the block **commented out** (the
hardware secret-key secureboot setup is still applied).

### Bitwarden-desktop

The user removed the `bitwarden-desktop` line from
`modules/aspects/system/desktop.nix` (a commit by
`m00nwtchr <m00n@naktis.eu>` to keep the build working without
the package). It is currently commented out.

### Sops secrets file paths

The source repo's `flake.nix:101-105` injects
`pkgsStable` via `_module.args`, and the legacy `sops-nix.nix`
module's `defaultSopsFile` uses `${inputs.self}/systems/...`
paths. The den port's `modules/aspects/system/sops.nix` uses
`${inputs.self}/hosts/${hostName}/secrets/default.yaml`
(matching the new data-dir layout under `~/nixnew/hosts/tide/secrets/`).

### Disko btrfs-on-LUKS

The source's `disko` config is in
`systems/x86_64-linux/tide/disk-config.nix`. The den port has it
as a sub-aspect `den.aspects.hosts.tide-disk` in
`modules/aspects/hosts/tide.nix`, included from `den.aspects.tide`.
The `disko.imageBuild.qemu = false` line from the source was
dropped (option no longer exists in current disko).

### Framework 16 hardware

The source's tide default.nix imports
`inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series`.
The den port does the same in `den.aspects.hosts.tide.nixos.imports`.
The `nixos-hardware` input is declared via
`flake-file.inputs.nixos-hardware` in the same file (per the
co-location rule).

## Key configuration files (top-level)

These files at the repo root or in `modules/` are not aspects
themselves but provide the den schema wiring:

* **`flake.nix`**: auto-generated by `nix run .#write-flake`. NOT
  to be edited by hand. Reads `modules/` via
  `import-tree`. Regenerate after adding/removing aspects.

* **`modules/dendritic.nix`**: imports the framework plugins
  (`flake-file`, `den`), registers the `hardware` and `users`
  namespaces, and declares the three meta flake-file inputs
  (`den`, `flake-file`, `home-manager`). All other flake-file
  inputs are co-located in their consuming aspect files.

* **`modules/defaults.nix`**: sets the `den.default` config
  (stateVersion, allowUnfree, permittedInsecurePackages for
  both nixos and homeManager), the default user class
  (`den.schema.user.classes = [ "homeManager" ]`), and the
  default `den.default.includes` (`<den/hostname>`,
  `<den/define-user>`, `<hardware/facter>`).

* **`modules/hosts.nix`**: the bridge between the den schema's
  host/user system and the actual aspects. Declares
  `den.hosts.x86_64-linux.tide.users.m00n = {};` which causes
  den to create the `tide` host entity and the `m00n` user
  entity, then run the host and user aspect chains.

* **`modules/nh.nix`**: kept as-is from the original template.
  Configures the `nh` (Nix Helper) CLI tool integration. Not
  modified by this port.

* **`modules/vm.nix`**: kept as-is from the original template.
  VM-related utilities. Not used by the tide build.

* **`hosts/tide/default.nix`**: an empty data anchor file. The
  den schema treats each subdirectory of `hosts/` as a host
  entity by its name; this file exists so the directory is
  tracked by git. The actual NixOS configuration lives in
  `modules/aspects/hosts/tide.nix` (the host aspect).

* **`hosts/tide/host-seed`**: a small file of random bytes
  read by `modules/aspects/hardware/zfs.nix` to derive
  `networking.hostId` (a stable 8-char hex string from
  `hashString "sha256" host-seed`). The file is read at build
  time; it is not a sops secret.

* **`hosts/tide/facter.json`**: per-host hardware report
  generated by `nixos-facter`. Loaded by the `facter` aspect
  which derives `hardware.facter.detected.{wireless,isLaptop,
  isDesktop,nvidia}` for use by downstream conditional
  aspects.

* **`hosts/tide/rfkill-wlan0.nix`**: a copy of the same content
  as `modules/aspects/system/rfkill-wlan0.nix`. The aspect
  is what's actually applied. The data file is kept for
  source compatibility but is dead code; can be deleted
  without affecting the build.

## What's TODO (in priority order)

1. **`pkgsStable` aspect** (if/when needed): see "deferred" above.
2. **Lanzaboote `measuredBoot` block**: currently commented out
   (waiting for lanzaboote to support current nixpkgs).
3. **Bitwarden-desktop**: currently commented out.
4. **Source overlays** (`~/nixos-config/overlays/`): not ported.
   Tide doesn't use them, so this is fine for now.
5. **`nixConfig` (extra-substituters, trusted-public-keys)**: not
   ported. The auto-generated `flake.nix` from `nix run .#write-flake`
   doesn't expose `nixConfig`. The source's `flake.nix` had:
   ```nix
   nixConfig = {
     extra-substituters = [
       "https://nix-community.cachix.org"
       "https://attic.m00nlit.dev/m00n-system"
     ];
     extra-trusted-public-keys = [
       "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
       "m00n-system:VibP74fZiSuiC8WaYCoLfn5jrfcQ7cyBht0baynxxCY="
     ];
   };
   ```
   To add it: create a small flake-parts module (e.g.
   `modules/nix-config.nix`) that injects `nix.settings.substituters`
   and `nix.trustedPublicKeys` via the flake-parts `nix` module,
   then import-tree will pick it up. The system.nix already sets
   `nix.settings.trusted-public-keys = [ "m00n:..." ]` for the
   user-local key, but the auto-generated flake.nix doesn't
   expose the binary cache config.
6. **Sops secrets re-encryption**: not in scope. The build
   succeeds with the sops files as copied from source; if
   deploy requires fresh encryption, the user can re-encrypt
   with their own age key as a separate step.

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
│   ├── facter.json
│   ├── host-seed
│   ├── secrets/default.yaml            (sops-encrypted)
│   ├── easyeffects/amesb fw16 EE profile.json
│   └── rfkill-wlan0.nix
│
├── home/m00n/                           (home data dir for m00n)
│   ├── bin/uwsm-game.sh
│   ├── sway/{config, default.nix, icc/}
│   ├── wallust/{default.nix, wallust.toml, templates/}
│   ├── dunst/default.nix
│   └── waybar/{default.nix, layout.nix, modules.nix, custom.nix, style.css}
│
└── modules/
    ├── defaults.nix                     (stateVersion, allowUnfree, classes)
    ├── dendritic.nix                    (flake-file inputs: den, flake-file, home-manager)
    ├── hosts.nix                        (den.hosts.x86_64-linux.tide.users.m00n)
    │
    └── aspects/
        ├── boot.nix                     (den.aspects.boot, +secureboot sub-aspect,
        │                                  flake-file: lanzaboote)
        │
        ├── hosts/
        │   └── tide.nix                 (den.aspects.tide + den.aspects.hosts.tide
        │                                  + den.aspects.hosts.tide-disk
        │                                  flake-file: nixos-hardware, disko, disko-zfs)
        │
        ├── users/
        │   └── m00n.nix                 (den.aspects.m00n + provides.to-hosts.nixos)
        │
        ├── system/
        │   ├── system.nix
        │   ├── desktop.nix
        │   ├── splash.nix
        │   ├── sops.nix                 (flake-file: sops-nix)
        │   ├── podman.nix
        │   ├── vms.nix
        │   ├── gaming.nix
        │   ├── rfkill-wlan0.nix
        │   ├── autologin.nix            (TTY1 autologin as m00n)
        │   ├── wayland.nix              (NixOS-side: portal, fonts,
        │   │                              thunar, gvfs, udisks2, tumbler)
        │   ├── wayland-sway.nix         (NixOS-side: programs.uwsm,
        │   │                              programs.sway, xdg.portal.wlr)
        │   └── home-manager.nix         (useGlobalPkgs, useUserPackages)
        │
        ├── hardware/
        │   ├── facter.nix               (loads facter.json; declares
        │   │                              hardware.facter.detected.{wireless,
        │   │                              isLaptop,isDesktop,nvidia})
        │   ├── amdgpu.nix               (den.aspects.amdgpuDynamicVram)
        │   ├── wireless.nix
        │   ├── laptop.nix
        │   ├── nvidia.nix
        │   └── ppd-auto.nix
        │
        └── home/                        (17 sub-aspects of home + 1 stub)
            ├── autostart.nix
            ├── containers.nix
            ├── default.nix
            ├── dev.nix                  (flake-file: alejandra)
            ├── dunst.nix
            ├── env.nix
            ├── gpg.nix
            ├── modules-dotfiles.nix     (stub)
            ├── rclone.nix
            ├── rust.nix
            ├── shell.nix
            ├── ssh.nix
            ├── sway.nix
            ├── wallust.nix
            ├── waybar.nix
            ├── wayland.nix
            ├── uwsm.nix                 (programs.uwsm.environment + env vars)
            ├── uwsm-modules.nix         (programs.uwsm option type)
            ├── easyeffects.nix
            └── kubeconfig.nix
```

## Verification

### Build

```bash
# Build the tide NixOS configuration (pulls all derivations):
nix run .#tide -- build
# → builds nixos-system-tide-26.05.<rev>
# → SIZE: 50.7 GiB -> ~49.7 GiB (DIFF: -1.05 GiB)
# (the exact SIZE depends on the nixpkgs revision pulled by
# the lock file; the running system uses 26.11.20260606 and the
# port uses 26.11.20260611, so most of the remaining diff is
# version churn)
```

### Flake validation

```bash
# Validate the flake structure (catches obvious errors):
nix flake check
# (Note: this evaluates the full flake; may take a while)

# Show the flake outputs (what's exposed):
nix flake show
# → apps, checks, devShells, formatter, legacyPackages, modules,
#   nixosConfigurations, nixosModules, overlays, packages
```

### Regenerate flake.nix

```bash
# After adding/removing/renaming aspect files, regenerate:
nix run .#write-flake
# → updates flake.nix with the current set of flake-file inputs
# → safe to run repeatedly; idempotent
```

### Spot-check NixOS options

```bash
# Top-level system stateVersion:
nix eval .#nixosConfigurations.tide.config.system.stateVersion
# → "26.05"

# Hardware detection (from facter.json):
nix eval .#nixosConfigurations.tide.config.hardware.facter.detected.isLaptop
# → true

# Custom m00n-namespaced options:
nix eval .#nixosConfigurations.tide.config.services.m00n.ppd-auto.enable
# → true
```

### Spot-check home options

```bash
# HomeConfigurations are exposed as a flat attrset (no @host suffix):
nix eval .#homeConfigurations --apply 'builtins.attrNames'
# → [ "m00n" ]

# Check an individual option:
nix eval .#homeConfigurations.m00n.config.services.easyeffects.enable
# → true

nix eval .#homeConfigurations.m00n.config.programs.alacritty.settings.terminal.shell
# → ".../uwsm-shell/bin/uwsm-shell"
```

## Critical user actions (before deploy)

1. **Re-encrypt or copy the atuin key** if migrating from an
   old host: `secrets/atuin_key.txt` is the binary atuin key;
   without it, the atuin sync won't authenticate.

## Out of scope

* Other hosts in `~/nixos-config` (ember, kepler, ganymede, beacon)
* The `k3s` system module (ganymede-specific)
* The `clamav`, `greeter` modules (commented out in source)
* The `~/nixos-config/overlays/` (jool, pywalfox, safeeyes)
* `lanzaboote` v0.4.3 measuredBoot — waiting on upstream fix
* `pkgsStable` — see deferred section above
* `nixConfig` — see TODO above
* Sops secrets re-encryption — user action (not in scope)
