{
  lib,
  pkgs,
  config,
  ...
}: {
  sops.secrets."passwords/m00n".neededForUsers = true;

  users.users.m00n = {
    isNormalUser = true;
    uid = 1000;
    group = "m00n";
    shell = pkgs.zsh;

    hashedPasswordFile = config.sops.secrets."passwords/m00n".path;
    openssh.authorizedKeys.keyFiles = [../secrets/authorized_keys];

    extraGroups =
      ["wheel"]
      ++ (
        if config.security.tpm2.enable
        then ["tss"]
        else []
      );
  };
  users.groups.m00n.gid = 1000;

  home-manager.users.m00n = import ../home;
}
