{
  lib,
  inputs,
  ...
}: {
  # Port of legacy/modules/efi/default.nix + legacy/modules/efi/secureboot.nix
  # from the source nixos-config. The base EFI setup is the `nixos`
  # class; the `secureboot` sub-aspect (which is a Lanzaboote
  # wrapper) extends it via `includes` once the secureboot
  # sub-aspect is itself included from a host.
  den.aspects.boot = {config, ...}: {
    includes = [config.secureboot];
    nixos = {
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

    secureboot.nixos = {
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

      environment.systemPackages = [
        # For debugging and troubleshooting Secure Boot.
        pkgs.sbctl
      ];
    };
  };

  flake-file.inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
