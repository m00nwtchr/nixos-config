{
  pkgs,
  config,
  lib,
  ...
}: {
  environment.systemPackages =
    []
    ++ (
      if config.security.tpm2.enable
      then [pkgs.ssh-tpm-agent]
      else []
    );

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
