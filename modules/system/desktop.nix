{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./default.nix
    # ../clamav.nix

    ../home-manager.nix
    ../../users/m00n.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    trusted-users = ["m00n"];
  };

  nixpkgs.overlays = [
    (import ../../overlays/safeeyes.nix)
    (import ../../overlays/lens.nix)
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [
    "nowatchdogs"
    "nmi_watchdog=0"
  ];

  hardware.graphics.enable = true;
  hardware.nvidia.powerManagement.enable = true;

  sops.secrets."passwords/root".neededForUsers = true;
  users.users.root.hashedPasswordFile = config.sops.secrets."passwords/root".path;

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

  programs.adb.enable = true;

  security.tpm2 = {
    # enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  security.pam.services = {
    # login.u2fAuth = true;
    # sudo.u2fAuth = true;
    # swaylock.u2fAuth = true;
  };
  security.rtkit.enable = true;

  # mDNS
  networking.firewall.allowedUDPPorts = [5353];
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
