{
  config,
  lib,
  pkgs,
  ...
}: {
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
  };
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    scdaemonSettings = {
      card-timeout = "5";
      disable-ccid = true;
    };
  };
}
