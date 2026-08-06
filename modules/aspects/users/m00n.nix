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
      <home/rclone>
      <home/wayland>
    ];

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        htop

        xdg-user-dirs

        papers
        libreoffice-qt6-fresh

        # bitwarden-desktop
        calibre

        android-tools
      ];
    };

    # NixOS-side user definition. Source equivalent:
    # legacy/users/m00n.nix (sops + users.users.m00n + extras).
    provides.to-hosts = {host, ...}: {
      includes = [<system/wayland/sway>];
      nixos = {
        config,
        pkgs,
        ...
      }: {
        sops.secrets."passwords/m00n".neededForUsers = true;

        users.users.m00n = {
          uid = 1000;
          group = "m00n";

          hashedPasswordFile = config.sops.secrets."passwords/m00n".path;
          openssh.authorizedKeys.keyFiles = [
            (builtins.toString "${inputs.self}/secrets/authorized_keys")
          ];

          autoSubUidGidRange = true;

          extraGroups =
            [
              "wheel"
              "video"
              "dialout"
              "adbusers"
            ]
            ++ (
              if config.security.tpm2.enable
              then ["tss"]
              else []
            );
        };
        users.groups.m00n.gid = 1000;

        # memlock unlimited for m00n
        security.pam.loginLimits = [
          {
            domain = "m00n";
            type = "soft";
            item = "memlock";
            value = "unlimited";
          }
          {
            domain = "m00n";
            type = "hard";
            item = "memlock";
            value = "unlimited";
          }
        ];

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
  };
}
