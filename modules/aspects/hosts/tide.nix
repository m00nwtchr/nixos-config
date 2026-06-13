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
      <system/disk/swap>
    ];
    nixos = {lib, ...}: {
      boot.kernelParams = ["resume_offset=533760"];
    };
  };

  den.aspects.tide = {
    includes = [
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
    # provides.to-users.homeManager = {pkgs, ...}: {
    #   home.packages = with pkgs; [
    #     # rocm userspace tools
    #     clinfo
    #     rocmPackages.clr.icd
    #     rocmPackages.rocminfo
    #   ];
    # };
  };
}
