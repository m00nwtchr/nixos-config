{
  pkgs,
  lib,
  ...
}: {
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PermitRootLogin = "prohibit-password"; # disable root login
      PubkeyAuthentication = true;
      PasswordAuthentication = false; # disable password login
      KbdInteractiveAuthentication = false;
      PermitEmptyPasswords = false;
    };
    openFirewall = true;
  };
}
