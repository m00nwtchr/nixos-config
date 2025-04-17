{
  config,
  inputs,
  lib,
  ...
}: let
  defaultFacterPath = "${inputs.self}/hosts/${config.networking.hostName}/facter.json";
in {
  # sops.secrets.facter = lib.mkIf (builtins.pathExists defaultFacterPath) {
  #   sopsFile = defaultFacterPath;
  #   format = "json";
  # };

  # facter.reportPath = lib.mkIf (builtins.pathExists defaultFacterPath) config.sops.secrets.facter.path;

  facter.reportPath = lib.mkIf (builtins.pathExists defaultFacterPath) defaultFacterPath;
}
