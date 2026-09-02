# Port of modules/nixos/hardware/facter/default.nix — facter
# detection: wireless, isLaptop, isDesktop, nvidia. Loads
# hosts/<host>/facter.json and exposes a `facter` policy that
# the wireless/laptop/nvidia/btrfs aspects depend on.
{
  den,
  hardware,
  lib,
  __findFile ? __findFile,
  ...
}: let
  inherit (den.lib.policy) resolve include;
in {
  # Aspect: `hardware.facter` — loads the per-host facter.json
  # and derives detected.{wireless,isLaptop,isDesktop,nvidia}.
  hardware.facter = {
    nixos = {lib, ...}: {
      options.hardware.facter.detected = {
        wireless = lib.mkEnableOption "";
        isLaptop = lib.mkEnableOption "";
        isDesktop = lib.mkEnableOption "";
        nvidia = lib.mkEnableOption "";
      };
    };

    policies.load-facter = {host, ...}: let
      facterPath = ../../../hosts/${host.hostName}/facter.json;
    in (lib.optionals
      (builtins.pathExists facterPath)
      [
        (resolve {
          facter = builtins.fromJSON (builtins.readFile facterPath);
        })
        (include (
          {
            host,
            facter,
          }: {
            nixos.hardware.facter.reportPath = facterPath;
            nixos.hardware.facter.detected = {
              wireless =
                builtins.any
                (iface: (iface ? sub_class) && (iface.sub_class ? hex) && iface.sub_class.hex == "000a")
                (
                  if facter ? hardware && facter.hardware ? network_interface
                  then facter.hardware.network_interface
                  else []
                );

              isLaptop =
                if facter ? hardware && facter.hardware ? system && facter.hardware.system ? form_factor
                then facter.hardware.system.form_factor == "laptop"
                else false;

              isDesktop =
                if facter ? hardware && facter.hardware ? system && facter.hardware.system ? form_factor
                then facter.hardware.system.form_factor == "desktop"
                else false;

              nvidia = builtins.any (gpu: (gpu ? driver) && gpu.driver == "nvidia") (
                if facter ? hardware && facter.hardware ? graphics_card
                then facter.hardware.graphics_card
                else []
              );
            };
          }
        ))
      ]);

    includes = [
      hardware.facter.policies.load-facter
      <hardware/amdgpu>
      <hardware/network>
      <hardware/laptop>
      <hardware/nvidia>
    ];
  };
}
