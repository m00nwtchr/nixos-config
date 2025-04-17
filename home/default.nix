{
  config,
  lib,
  pkgs,
  system,
  inputs,
  ...
}: {
  imports = [
    ./env.nix
    ./wayland.nix
    ./shell.nix
    ./dev.nix

    ./modules/dotfiles.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "m00n";
  home.homeDirectory = "/home/m00n";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # home.file.".cargo/config.toml".text = ''
  #   [target.x86_64-unknown-linux-gnu]
  #   rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  # '';

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    ungoogled-chromium
    inputs.zen-browser.packages."${system}".default

    overskride
    helvum
    pavucontrol

    yubioath-flutter
    yubikey-manager
    keepassxc

    nheko
    cinny-desktop
    (discord.override {
      withOpenASAR = true;
    })
    vesktop

    imv
    gimp

    gnome-calculator
    obsidian

    yt-dlp
    pwgen
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  programs.librewolf = {
    enable = true;
    package = pkgs.librewolf.override {
      nativeMessagingHosts = with pkgs; [
        pywalfox-native # Doesn't actually work as a nativeMessagingHost package because it doesn't contain a manifest.
      ];
    };
  };

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      mpris
    ];

    config = {
      osc = true;
      vo = "gpu-next";
      ao = "pipewire";

      hwdec = "auto-safe";

      ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
      screenshot-template = "%F - [%P]v%#01n";
    };

    profiles = {
      hq = {
        profile = "gpu-hq";
        scale = "ewa_lanczos";
        cscale = "ewa_lanczos";
        video-sync = "display-resample";
        interpolation = true;
        #tscale="oversample";
        tscale = "sphinx";
        tscale-blur = "0.6991556596428412";
        ytdl-format = "bestvideo+bestaudio/best";
      };
    };
  };

  services = {
    easyeffects.enable = true;

    syncthing = {
      enable = true;
      tray.enable = true;
    };
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
