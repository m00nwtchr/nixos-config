# Host aspect for tide. Wires together the aspects that make up
# tide's NixOS configuration.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  # Sub-aspect: Framework 16 / ROCm / ollama / wireplumber config.
  den.aspects.hosts.tide = {
    nixos = {pkgs, ...}: {
      nixpkgs.config.rocmSupport = true;
      nixpkgs.overlays = [];

      hardware.amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
        dynamicVram = {
          enable = true;
          vramGiB = 30;
        };
      };

      # memlock unlimited for m00n
      security.pam.loginLimits = [
        {
          domain = "m00n";
          type = "soft";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = "m00n";
          type = "hard";
          item = "memlock";
          value = "unlimited";
        }
      ];

      security.tpm2.enable = true;

      networking.bridges = {
        "br0" = {
          interfaces = ["wlan0"];
        };
      };

      hardware.alsa.enablePersistence = true;

      environment.systemPackages = with pkgs; [
        clinfo
        rocmPackages.clr.icd
        rocmPackages.rocminfo
      ];

      programs.nix-ld.libraries = with pkgs.rocmPackages; [
        hipblas
        rocblas
        numactl
        elfutils
      ];

      services.tailscale.enable = true;

      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        environmentVariables = {};
      };

      services.pipewire.wireplumber.extraConfig = {
        "disable-extra-mic"."monitor.alsa.rules" = [
          {
            matches = [
              {
                "node.nick" = "ALC285 Analog";
                "device.profile.description" = "Stereo Microphone";
              }
            ];
            actions = {
              update-props = {
                "node.disabled" = true;
              };
            };
          }
        ];

        "set-speaker-profile"."monitor.alsa.rules" = [
          {
            matches = [
              {"device.name" = "alsa_card.pci-0000_c1_00.6";}
            ];
            actions = {
              update-props = {
                "device.profile" = "HiFi (Mic1, Mic2, Speaker)";
                "api.alsa.soft-mixer" = true;
              };
            };
          }
        ];
      };
    };
  };

  den.aspects.tide = {
    includes = [
      <boot>
      <system>
      <system/desktop>
      <system/splash>
      <system/sops>
      <system/podman>
      <system/vms>
      <system/gaming>
      <system/rfkill-wlan0>
      <hardware/facter>

      # AMD dynamic VRAM tuning (defines hardware.amdgpu.dynamicVram)
      den.aspects.amdgpuDynamicVram

      # Tide-specific (Framework 16, ROCm, ollama, wireplumber)
      den.aspects.hosts.tide
    ];

    # Tide-specific overrides go here. (Source equivalent:
    # systems/x86_64-linux/tide/default.nix.)
    nixos = {
      system.stateVersion = "26.05";
      networking.hostName = "tide";

      # TODO: replace with disko btrfs-on-luks config (the disk
      # aspect). For now, a placeholder so the system can build.
      fileSystems."/" = {
        device = "/dev/fake";
        fsType = "auto";
      };
      boot.loader.systemd-boot.enable = false;
    };

    # Provides: tide adds default packages to every user home on
    # this host.
    provides.to-users.homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        # rocm userspace tools
        clinfo
        rocmPackages.clr.icd
        rocmPackages.rocminfo
      ];
    };
  };
}
