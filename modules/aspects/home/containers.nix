# Port of homes/x86_64-linux/m00n/containers.nix — kubectl,
# helm, k9s, etc. + podman user service.
{
  lib,
  inputs,
  den,
  ...
}: {
  flake-file.inputs.sofka = {
    url = "github:nklmilojevic/sofka";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.aspects.home.winboat = {
    nixos = {config, ...}: {
      nixpkgs.config.permittedInsecurePackages = [
        "electron-40.10.5"
      ];

      boot.extraModulePackages = [
        config.boot.kernelPackages.kvmfr
      ];
      boot.kernelModules = ["kvmfr"];
      boot.extraModprobeConfig = ''
        options kvmfr static_size_mb=128
      '';

      services.udev.extraRules = ''
        SUBSYSTEM=="kvmfr", KERNEL=="kvmfr0", OWNER="m00n", GROUP="kvm", MODE="0660"
      '';
    };

    homeManager = {
      pkgs,
      inputs',
      config,
      ...
    }: {
      home.packages = with pkgs; [
        winboat

        looking-glass-client
        # (
        #   pkgs.looking-glass-client.overrideAttrs (final: prev: {
        #     version = "cdba29f2f6bcae3ded26369fc231a067cbca3752";

        #     src = prev.src.override {
        #       rev = final.version;
        #       hash = "sha256-/QE1Hre4Q7YplkudZZ7DSzmosY/MJc1XiAy69xcBXg4=";
        #     };

        #     buildInputs = prev.buildInputs ++ [pkgs.fuse3 pkgs.libunwind pkgs.elfutils];

        #     patches = [];
        #   })
        # )
      ];

      wayland.windowManager.sway = let
        cfg = config.wayland.windowManager.sway.config;
        mod = cfg.modifier;

        windowsWorkspace = pkgs.writeShellScript "windows-workspace" ''
          ${pkgs.sway}/bin/swaymsg workspace windows

          if ${pkgs.procps}/bin/pgrep -f '(^|/)looking-glass-client([[:space:]]|$)' >/dev/null; then
            exit 0
          fi

          ${pkgs.looking-glass-client}/bin/looking-glass-client \
            -f /dev/kvmfr0 -c 127.0.0.1 -p $(podman port WinBoat | grep "5930" | awk -F: '{print $2}') \
            win:appId="looking-glass-windows" \
            input:escapeKey=KEY_LEFTCTRL

          if ${pkgs.sway}/bin/swaymsg -t get_workspaces |
            ${pkgs.jq}/bin/jq -e 'any(.[]; .focused and .name == "windows")' >/dev/null; then
            ${pkgs.sway}/bin/swaymsg workspace back_and_forth
          fi
        '';
      in {
        extraConfig = ''
          bindsym ${mod}+Shift+w workspace windows; exec ${windowsWorkspace}
          assign [app_id="looking-glass-windows"] workspace windows
          for_window [app_id="looking-glass-windows"] fullscreen enable
        '';
      };
    };
  };

  den.aspects.home.containers = {
    includes = [
      den.aspects.home.winboat
    ];

    homeManager = {pkgs, ...}: {
      imports = [inputs.sofka.homeManagerModules.default];

      home.packages = with pkgs; [
        kubectl
        krew
        kubelogin-oidc
        kubernetes-helm
        # k9s

        cilium-cli

        k3d

        talosctl
        talhelper

        docker-compose

        lens
      ];

      programs.sofka = {
        enable = true;
      };

      services.podman = {
        enable = true;
        autoUpdate.enable = true;
      };

      systemd.user.sockets.podman = {
        Unit = {
          Description = "Podman API Socket";
          Documentation = "man:podman-system-service(1)";
        };
        Socket = {
          ListenStream = "%t/podman/podman.sock";
          SocketMode = "0660";
        };
        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };
  };
}
