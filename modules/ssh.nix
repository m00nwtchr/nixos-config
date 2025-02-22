{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./ssh-tpm-agent.nix
  ];

  services.sshTpmAgent.hostKeys = false;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password"; # disable root login
      PubkeyAuthentication = true;
      PasswordAuthentication = false; # disable password login
      KbdInteractiveAuthentication = false;
      PermitEmptyPasswords = false;
    };
  };
}
