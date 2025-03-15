{
  pkgs,
  lib,
  ...
}: let
  authorizedKeys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMiN+HEhea2/1MMqp5ao55NHZzIg11TyeUGIHhnRxfwJAAAABHNzaDo= m00n@yubikey"
  ];
in {
  imports = [
    ./default.nix
    ../ssh.nix
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nnn # terminal file manager
  ];

  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
  services.openssh = {
    authorizedKeysCommand = "/opt/kanidm_ssh_authorizedkeys %u";
    authorizedKeysCommandUser = "nobody";
    settings = {
      UsePAM = true;
    };
  };

  system.activationScripts.copyFile = ''
    cp ${pkgs.kanidm}/bin/kanidm_ssh_authorizedkeys /opt/kanidm_ssh_authorizedkeys
    chown root:root /opt/kanidm_ssh_authorizedkeys
    chmod 0755 /opt/kanidm_ssh_authorizedkeys
  '';

  virtualisation.containers.storage.settings = {
    driver = "btrfs";
  };

  networking.timeServers = [
    "time.cloudflare.com"
    "ntp3.fau.de"
    "ptbtime1.ptb.de"
    "ntp2.glypnod.com"
  ];

  services = {
    chrony = {
      enable = true;
      enableNTS = true;
    };

    kanidm = {
      # enableClient = true;
      enablePam = true;
      clientSettings = {
        uri = "https://idm.m00nlit.dev";
      };
      unixSettings = {
        version = "2";

        home_alias = "name";
        uid_attr_map = "name";
        gid_attr_map = "name";
        pam_allowed_login_groups = ["unix_admins"];

        kanidm = {
          pam_allowed_login_groups = ["unix_admins"];

          map_group = [
            {
              local = "wheel";
              "with" = "unix_admins";
            }
          ];
        };
      };
    };
  };
}
