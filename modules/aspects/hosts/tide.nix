# Host aspect for tide. Wires together the aspects that make up
# tide's NixOS configuration.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.tide.disk = {
    includes = [
      <system/disk/default>
    ];
    nixos = {lib, ...}: {
      boot.kernelParams = ["resume_offset=533760"];
    };
  };

  den.aspects.tide = {
    includes = [
      <system/autologin>
      <boot/secureboot>
      <system/desktop>
      <system/splash>
      <system/vms>
      <system/gaming>

      den.aspects.tide.disk
      <hardware/framework-16-amd-ai-300-series>
    ];

    nixos = {pkgs, ...}: {
      system.stateVersion = "26.11";

      environment.systemPackages = with pkgs; [
        clinfo
        rocmPackages.clr.icd
        rocmPackages.rocminfo
      ];

      programs.nix-ld.libraries = with pkgs.rocmPackages; [
        hipblas
        rocblas

        pkgs.numactl
        pkgs.elfutils

        mpi
      ];

      services.tailscale.enable = true;

      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        environmentVariables = {};
      };
    };

    # Provides: tide adds default packages to every user home on
    # this host.
    provides.to-users = {
      nixos = {
        # nixpkgs.config.permittedInsecurePackages = [
        #   # "python3.13-vllm-0.16.0"
        # ];
      };

      homeManager = {
        pkgs,
        pkgsStable,
        ...
      }: {
        home.packages = with pkgs; [
          # rocm userspace tools
          # clinfo
          # rocmPackages.clr.icd
          # rocmPackages.rocminfo
          #

          # pkgsStable.vllm
        ];
      };
    };
  };
}
