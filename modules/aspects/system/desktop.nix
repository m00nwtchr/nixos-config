# Port of legacy/modules/system/desktop.nix — desktop host config
# (extra system packages, kernel zen, nix-ld, appimage, gnupg,
# tpm2/pam, pipewire, pcscd, etc.). Imports the user m00n aspect
# so the user is created via the m00n aspect's `provides.to-hosts`.
{
  config,
  pkgs,
  lib,
  den,
  inputs,
  ...
}: {
  den.aspects.system.desktop = {
    nixos.imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    nixos = {
      boot.binfmt.emulatedSystems = ["aarch64-linux"];
      boot.supportedFilesystems = ["ntfs"];

      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "olm-3.2.16"
          "libsoup-2.74.3"
          "electron-39.8.10"
        ];
      };
      nix.settings = {
        trusted-users = ["m00n"];
        extra-sandbox-paths = [config.programs.ccache.cacheDir];
      };

      nixpkgs.overlays = [
        (self: super: {
          ccacheWrapper = super.ccacheWrapper.override {
            extraConfig = ''
              export CCACHE_COMPRESS=1
              export CCACHE_DIR="${config.programs.ccache.cacheDir}"
              export CCACHE_UMASK=007
              export CCACHE_SLOPPINESS=random_seed
              if [ ! -d "$CCACHE_DIR" ]; then
                echo "====="
                echo "Directory '$CCACHE_DIR' does not exist"
                echo "Please create it with:"
                echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
                echo "  sudo chown root:nixbld '$CCACHE_DIR'"
                echo "====="
                exit 1
              fi
              if [ ! -w "$CCACHE_DIR" ]; then
                echo "====="
                echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
                echo "Please verify its access permissions"
                echo "====="
                exit 1
              fi
            '';
          };
        })
      ];

      boot = {
        kernelPackages = pkgs.linuxPackages_zen;
        kernelParams = [
          "nowatchdog"
          "nmi_watchdog=0"
        ];
        kernel.sysctl."fs.inotify.max_user_watches" = 524288;
      };

      hardware.graphics.enable = true;
      hardware.nvidia.powerManagement.enable = true;

      sops.secrets."passwords/root".neededForUsers = true;
      users.users.root.hashedPasswordFile = config.sops.secrets."passwords/root".path;

      i18n = {
        defaultLocale = "en_GB.UTF-8";
        extraLocales = [
          "en_US.UTF-8/UTF-8"
          "pl_PL.UTF-8/UTF-8"
        ];
      };

      environment.systemPackages = with pkgs; [
        xdg-user-dirs

        papers
        libreoffice-qt6-fresh

        bitwarden-desktop

        android-tools
      ] ++ (if config.security.tpm2.enable then [pkgs.tpm2-tools] else []);

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-pipewire-audio-capture
          obs-vaapi
        ];

        enableVirtualCamera = true;
      };

      programs.ccache.enable = true;
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          glib
          nss
          nspr
          atk
          at-spi2-core
          cups
          dbus
          libdrm
          gtk3
          pango
          cairo
          gdk-pixbuf
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxkbcommon
          expat
          libxcb
          mesa
          libgbm
          alsa-lib
          libGL
        ];
      };
      programs.appimage = {
        enable = true;
        binfmt = true;
        package = pkgs.appimage-run.override {
          extraPkgs = pkgs: with pkgs; [];
        };
      };

      programs.gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gnome3;
      };
      services.dbus.packages = [pkgs.gcr];

      security.tpm2 = {
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };
      security.pam = {
        u2f.enable = true;
        services = {
          login.u2fAuth = true;
          sudo.u2fAuth = true;
          swaylock.u2fAuth = true;
        };
      };
      security.rtkit.enable = true;

      virtualisation.containers.enable = true;

      networking.firewall.allowedUDPPorts = [5353];
      services = {
        logind.settings.Login.HibernateDelaySec = 900;

        pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };

        usbguard = {
          enable = false;
          dbus.enable = true;
          IPCAllowedGroups = ["wheel"];
        };

        udev.extraRules = ''
          ACTION=="remove",\
           SUBSYSTEM=="usb",\
           ENV{PRODUCT}=="1050/407/571",\
           RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';

        resolved.settings.Resolve.MulticastDNS = lib.mkDefault "resolve";

        pcscd.enable = true;
      };
    };
  };

  flake-file.inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
