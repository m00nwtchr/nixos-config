# Host aspect for ember. Wires together the aspects that make up
# ember's NixOS configuration.
{
  den,
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.ember.disk = {
    includes = [
      <system/disk/swap>
    ];
    nixos = {lib, ...}: {
      boot.kernelParams = ["resume_offset=533760"];
    };
  };

  den.aspects.ember = {
    includes = [
      <boot/secureboot>
      <system/desktop>
      <system/splash>
      <system/vms>
      <system/gaming>

      den.aspects.ember.disk
      <hardware/framework-16-amd-ai-300-series>
      den.aspects.vm
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

    # Provides: ember adds default packages to every user home on
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
