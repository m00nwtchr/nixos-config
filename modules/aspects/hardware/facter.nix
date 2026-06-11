{
  den,
  hardware,
  lib,
  __findFile ? __findFile,
  ...
}: let
  inherit (den.lib.policy) resolve include;
in {
  hardware.facter = {
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
          }
        ))
      ]);

    includes = [
      hardware.facter.policies.load-facter
      <hardware/amdgpu>
    ];
  };
}
