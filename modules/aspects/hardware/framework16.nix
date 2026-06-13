{
  den,
  hardware,
  inputs,
  lib,
  __findFile ? __findFile,
  ...
}: {
  flake-file.inputs.nixos-hardware = {
    url = "github:NixOS/nixos-hardware/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  hardware.framework-16-amd-ai-300-series = {
    includes = [
      (<system/rfkill> "wlan0")
    ];
    nixos = {pkgs, ...}: {
      imports = [
        inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
      ];

      boot.extraModprobeConfig = "blacklist sp5100_tco";
      security.tpm2.enable = true;

      hardware.alsa.enablePersistence = true;
      hardware.amdgpu.dynamicVram = {
        enable = true;
        vramGiB = 30;
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
}
