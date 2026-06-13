{
  den,
  lib,
  inputs,
  ...
}: {
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.boot.nixos = {
    boot.initrd.systemd.enable = true;

    boot.loader.efi.efiSysMountPoint = "/efi";
    boot.loader.efi.canTouchEfiVariables = true;

    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.systemd-boot = {
      enable = lib.mkDefault true;
      configurationLimit = 10;
      consoleMode = "max";
    };
  };

  den.aspects.boot.secureboot = {
    includes = [
      den.aspects.boot
    ];

    nixos = {
      host,
      pkgs,
      ...
    }: {
      imports = [inputs.lanzaboote.nixosModules.lanzaboote];

      boot.loader.systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = lib.mkForce 8;
      };
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        measuredBoot = {
          enable = true;
          pcrs = [
            0
            1
            2
            3
            4
            7
          ];
        };
      };

      # For debugging and troubleshooting Secure Boot.
      environment.systemPackages = with pkgs; [
        sbctl
      ];
    };
  };
}
