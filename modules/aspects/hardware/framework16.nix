{
  den,
  hardware,
  inputs,
  lib,
  __findFile ? __findFile,
  ...
}: {
  flake-file.inputs = {
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fw16-uleds = {
      url = "github:m00nwtchr/fw16-uleds";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  hardware.framework-16-amd-ai-300-series = {
    includes = [
      (<system/rfkill> "wlan0")
    ];
    nixos = {pkgs, ...}: {
      imports = [
        inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
        inputs.fw16-uleds.nixosModules.default
      ];

      boot.extraModprobeConfig = "blacklist sp5100_tco";
      security.tpm2.enable = true;

      hardware.alsa.enablePersistence = true;
      hardware.amdgpu.dynamicVram = {
        enable = true;
        vramGiB = 30;
      };

      services.fw16-uleds = {
        enable = true;
        pollMs = 1000;
      };

      # https://linrunner.de/tlp/faq/ppd.html#why-does-framework-recommend-power-profiles-daemon-over-tlp-for-its-amd-models
      services.power-profiles-daemon.enable = lib.mkForce false;
      services.tlp.settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkForce "";
        CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkForce "";
        CPU_ENERGY_PERF_POLICY_ON_SAV = lib.mkForce "";

        PLATFORM_PROFILE_ON_AC = lib.mkForce "performance";
        PLATFORM_PROFILE_ON_BAT = lib.mkForce "balanced";
        PLATFORM_PROFILE_ON_SAV = lib.mkForce "low-power";

        RUNTIME_PM_ON_AC = lib.mkForce "";
        RUNTIME_PM_ON_BAT = lib.mkForce "";
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

        # WF-1000XM5 profile swap helper is wired below in
        # programs.xm5-audio-status — see that block. We could not enable
        # BAP/LC3 here because the running kernel (linuxPackages_zen, no
        # CONFIG_BT_ISO/CIS support) lacks the ISO socket primitives bluez5
        # needs for the BAP plugin to initialize. Stick with auto switching
        # between A2DP-Sink (LDAC) and HFP/HS (mSBC) until a kernel with
        # CONFIG_BT_ISO/CIS is supplied.
      };
    };
  };
}
