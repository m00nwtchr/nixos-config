{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.services."user@".serviceConfig.Delegate = "yes";

  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "podman";
    podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
