# Port of legacy/modules/ssh.nix — enables services.openssh on
# port 2222 with kanidm authorizedKeysCommand, plus the
# services.sshTpmAgent skeleton. The ganymede host aspect forces
# services.sshTpmAgent.enable = false (matching nixold).
{
  __findFile ? __findFile,
  pkgs,
  config,
  lib,
  ...
}: {
  den.aspects.system.ssh = {
    nixos = {...}: {
      services.sshTpmAgent.enable = true;

      services.openssh = {
        enable = true;
        startWhenNeeded = true;
        openFirewall = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PubkeyAuthentication = true;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitEmptyPasswords = false;
          StreamLocalBindUnlink = true;
        };
      };
    };
  };
}
