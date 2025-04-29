{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation.containers.storage.settings.storage.driver = "btrfs";

  services.btrfs.autoScrub.enable = lib.mkDefault true;

  systemd.services."beesd@root" = lib.mkIf config.facter.detected.isLaptop {
    wantedBy = ["ac.target"];
    unitConfig = {
      BindsTo = ["ac.target"];
    };
    serviceConfig = {
      CPUQuota = "25%";
    };
  };
}
