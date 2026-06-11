{
  lib,
  inputs,
  ...
}: {
  den.aspects.boot = {config, ...}: {
    includes = [config.secureboot];
    nixos = {
      boot.initrd.systemd.enable = true;

      boot.loader.efi.efiSysMountPoint = "/efi";
      boot.loader.efi.canTouchEfiVariables = true;

      boot.loader.grub.enable = lib.mkForce false;
      boot.loader.systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 8;
        consoleMode = "max";
      };
    };

    secureboot.nixos = {
      host,
      pkgs,
      ...
    }: {
      imports = [inputs.lanzaboote.nixosModules.lanzaboote];

      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        # autoGenerateKeys.enable = true;
        # autoEnrollKeys = {
        #   includeMicrosoftKeys = false;
        #   includeChecksumsFromTPM = true;

        #   autoReboot = true;

        #   allowBrickingMyMachine = true;
        # };

        # measuredBoot = {
        #   enable = true;
        #   pcrs = [
        #     0
        #     4
        #     7
        #   ];
        # };
      };

      environment.systemPackages = [
        # For debugging and troubleshooting Secure Boot.
        pkgs.sbctl
      ];
    };
  };

  flake-file.inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
