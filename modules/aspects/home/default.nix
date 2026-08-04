# Port of homes/x86_64-linux/m00n/default.nix — the main m00n home
# entry: home.packages, xdg.mimeApps, librewolf, mpv, services
# (easyeffects, syncthing, activitywatch), Yubico u2f_keys.
{
  config,
  inputs,
  den,
  osConfig,
  ...
}: {
  den.aspects.home.default = {
    homeManager = {
      pkgs,
      config,
      ...
    }: {
      home.username = "m00n";
      home.homeDirectory = "/home/m00n";
      home.stateVersion = "26.11";

      home.packages = with pkgs; [
        ungoogled-chromium

        overskride
        crosspipe
        pavucontrol

        yubioath-flutter
        yubikey-manager
        keepassxc

        deskflow

        nheko
        element-desktop
        # sable
        discord
        discover-overlay
        signal-desktop

        vesktop

        imv
        gimp
        file-roller
        inkscape

        gnome-calculator
        obsidian

        yt-dlp
        pwgen

        aw-qt

        age
        age-plugin-yubikey

        qbittorrent
        protontricks
        qdirstat

        spotify

        recoll
        thunderbird
        jellyfin-desktop
        lmstudio
        zotero
      ];

      xdg.configFile."Yubico/u2f_keys".text = ''
        m00n:yxO+L99UucTy+hvAd5asbRx8SZRIr8SG3GI6QWtWYv5fUxzxa5D/tjZPv30Q8+75MaaE9ntMdsrJE4RxR0O1Aw==,nwYX9cckDOdOkTotQbDHQ4H8B2Zb/ug879VKUyrsaZ8pdRmGvORQgd/XFeCwMdJFtITuYkeK8XncFXWz0Rq9Xg==,es256,+presence+pin
      '';

      xdg.mimeApps = {
        enable = true;
        defaultApplicationPackages = with pkgs; [
          config.programs.librewolf.package # set in home/librewolf.nix
          imv
          papers
          libreoffice-qt6-fresh
        ];
      };

      programs.librewolf = {
        enable = true;

        nativeMessagingHosts = with pkgs; [
          pywalfox-native
          ff2mpv
        ];
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        profiles.userjs = let
          cssPath = "${pkgs.pywalfox-native}/${pkgs.python3.sitePackages}/pywalfox/assets/css";
        in {
          path = "7tpqbfqq.userjs";
          isDefault = true;
          userChrome = builtins.readFile "${cssPath}/userChrome.css";
          userContent = builtins.readFile "${cssPath}/userContent.css";
        };
      };

      programs.mpv = {
        enable = true;
        scripts = with pkgs.mpvScripts;
        with pkgs.mpvScripts.builtins; [
          mpris
          modernz
          sponsorblock
          thumbfast
          autoload
        ];

        config = {
          profile = "high-quality";
          vo = "gpu-next";

          gpu-api = "vulkan";
          fullscreen = true;
          taskbar-progress = false;
          force-seekable = true;
          keep-open = "always";

          reset-on-next-file = "pause";

          hwdec = "vulkan";
          dither-depth = 10;
          scale-antiring = 0.6;

          scale = "ewa_lanczossharp";
          dscale = "mitchell";
          cscale = "ewa_lanczossharp";

          gpu-shader-cache-dir = "~~cache/shaders";

          deband = false;
          deband-iterations = 2;
          deband-threshold = 64;
          deband-range = 17;
          deband-grain = 12;

          osd-bar = false;
          osc = false;
          border = true;
          cursor-autohide-fs-only = true;

          cursor-autohide = 300;
          osd-level = 1;
          osd-duration = 1000;
          hr-seek = true;

          osd-font = "Verdana";
          osd-font-size = 20;
          osd-color = "#FFFFFF";
          osd-border-color = "#000000";
          osd-border-size = 0.2;
          osd-blur = 0.2;

          alang = "ja,jp,jpn,en,eng";
          slang = "en,eng";

          volume = 100;
          audio-file-auto = "fuzzy";
          volume-max = 200;
          audio-pitch-correction = true;

          demuxer-mkv-subtitle-preroll = true;
          sub-fix-timing = false;
          sub-auto = "all";

          sub-font = "Netflix Sans Medium";
          sub-font-size = 40;
          sub-color = "#FFFFFFFF";
          sub-border-color = "#FF000000";
          sub-border-size = 2.0;
          sub-shadow-offset = 0;
          sub-spacing = 0.0;

          screenshot-format = "png";
          screenshot-high-bit-depth = true;
          screenshot-png-compression = 1;
          screenshot-directory = "~/Pictures/mpv-screenshots";
          screenshot-template = "%f-%wH.%wM.%wS.%wT-#%#00n";
        };

        scriptOpts = {
          ytdl_hook = {
            ytdl_path = "${pkgs.yt-dlp}/bin/yt-dlp";
          };
        };
      };

      services = {
        easyeffects.enable = true;

        syncthing = {
          enable = true;
          guiAddress = "[::1]:8384";
          tray.enable = true;
        };

        activitywatch = {
          enable = false;
          package = pkgs.aw-server-rust;
        };
      };

      programs.home-manager.enable = true;
    };
  };
}
