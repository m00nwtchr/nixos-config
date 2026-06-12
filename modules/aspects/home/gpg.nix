# Port of homes/x86_64-linux/m00n/gpg.nix — gpg-agent with
# Yubikey scdaemon, gpg in $XDG_DATA_HOME/gnupg.
{
  config,
  ...
}: {
  den.aspects.home.gpg = {
    homeManager = {pkgs, config, ...}: {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
        enableExtraSocket = true;
      };
      programs.gpg = {
        enable = true;
        homedir = "${config.xdg.dataHome}/gnupg";
        scdaemonSettings = {
          card-timeout = "5";
          disable-ccid = true;
        };
        settings = {
          auto-key-locate = "local,wkd";
          keyserver-options = "auto-key-retrieve";
        };
      };
    };
  };
}
