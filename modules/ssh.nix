{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./ssh-tpm-agent.nix
  ];

  services.sshTpmAgent.hostKeys = true;

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
