{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./default.nix
    ../home-manager.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [
    "nowatchdogs"
    "nmi_watchdog=0"
  ];

  users.users.m00n = {
    isNormalUser = true;
    extraGroups =
      ["wheel"]
      ++ (
        if config.security.tpm2.enable
        then ["tss"]
        else []
      );
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs;
    [
      xdg-user-dirs

      papers
      libreoffice-qt6-fresh
    ]
    ++ (
      if config.security.tpm2.enable
      then [pkgs.tpm2-tools]
      else []
    );

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    # enableSSHSupport = true;
  };
  services.dbus.packages = [pkgs.gcr];

  security.tpm2 = {
    # enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    swaylock.u2fAuth = true;
  };
  security.rtkit.enable = true;

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    usbguard = {
      enable = true;
      dbus.enable = true;
      IPCAllowedGroups = ["wheel"];
    };

    udev.extraRules = ''
      ACTION=="remove",\
       SUBSYSTEM=="usb",\
       ENV{PRODUCT}=="1050/407/571",\
       RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';

    resolved.extraConfig = lib.mkDefault ''
      MulticastDNS=resolve
    '';

    pcscd.enable = true;
  };
}
