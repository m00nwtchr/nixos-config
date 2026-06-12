# Port of legacy/users/m00n.nix — defines the `m00n` user, sops
# secrets, etc. The user-aspect is `den.aspects.m00n`; the
# `provides.to-hosts.nixos` sub-aspect is the NixOS-side user
# definition that gets applied to any host that includes this
# user (via `den.hosts.<arch>.<host>.users.<user>`).
{
  den,
  inputs,
  __findFile ? __findFile,
  ...
}: {
  den.aspects.m00n = {
    includes = [
      <den/primary-user>
      (<den/user-shell> "zsh")

      # Home sub-aspects
      <home/env>
      <home/dev>
      <home/shell>
      <home/rust>
      <home/containers>
      <home/ssh>
      <home/gpg>
      <home/rclone>
      <home/autostart>
      <home/wayland>
      <home/default>
      <home/sway>
      <home/wallust>
      <home/dunst>
      <home/waybar>
    ];

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.htop];
    };

    # NixOS-side user definition. Source equivalent:
    # legacy/users/m00n.nix (sops + users.users.m00n + extras).
    provides.to-hosts.nixos = {
      config,
      pkgs,
      ...
    }: {
      sops.secrets."passwords/m00n".neededForUsers = true;

      users.users.m00n = {
        isNormalUser = true;
        uid = 1000;
        group = "m00n";

        hashedPasswordFile = config.sops.secrets."passwords/m00n".path;
        openssh.authorizedKeys.keyFiles = [
          (builtins.toString ../../secrets/authorized_keys)
        ];

        autoSubUidGidRange = true;

        extraGroups =
          [
            "wheel"
            "adbusers"
            "video"
          ]
          ++ (
            if config.security.tpm2.enable
            then ["tss"]
            else []
          );
      };
      users.groups.m00n.gid = 1000;

      sops.secrets.atuin_key = {
        sopsFile = builtins.toString "${inputs.self}/secrets/atuin_key.txt";
        format = "binary";
        owner = config.users.users.m00n.name;
        group = config.users.users.m00n.group;
      };
      sops.secrets."atuin/session" = {
        owner = config.users.users.m00n.name;
        group = config.users.users.m00n.group;
      };

      sops.secrets."proton/password" = {
        sopsFile = builtins.toString "${inputs.self}/secrets/proton.yaml";
        owner = config.users.users.m00n.name;
        group = config.users.users.m00n.group;
      };
      sops.secrets."proton/otp_secret_key" = {
        sopsFile = builtins.toString "${inputs.self}/secrets/proton.yaml";
        owner = config.users.users.m00n.name;
        group = config.users.users.m00n.group;
      };
    };
  };
}
