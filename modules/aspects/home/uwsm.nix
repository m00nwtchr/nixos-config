{
  den,
  pkgs,
  lib,
  inputs,
  __findFile ? __findFile,
  ...
}: {
  den.aspects.home.uwsm = {
    includes = [
      <home/uwsm/module>
    ];

    homeManager = {
      pkgs,
      pkgsStable,
      config,
      osConfig,
      ...
    }: let
      app2unitPkg = pkgs.app2unit;
      app2unit = "${app2unitPkg}/bin/app2unit";

      uwsm-shell = pkgs.writeShellScriptBin "uwsm-shell" ''
        exec ${app2unit} -- $(getent passwd $USER | cut -d: -f7)
      '';

      uwsm-game = pkgs.writeShellScriptBin "uwsm-game" (builtins.readFile ../../../home/m00n/bin/uwsm-game.sh);
    in {
      programs.uwsm.environment =
        {
          WLR_RENDERER = "vulkan";

          QT_AUTO_SCREEN_SCALE_FACTOR = 1;
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          QT_QPA_PLATFORMTHEME = "qt6ct";

          _JAVA_AWT_WM_NONREPARENTING = 1;
          XCURSOR_SIZE = 24;

          MOZ_ENABLE_WAYLAND = 1;
          ECORE_EVAS_ENGINE = "wayland_egl";
          ELM_ENGINE = "wayland_egl";
          SDL_VIDEODRIVER = "wayland";
          SDL_AUDIODRIVER = "pipewire";
        }
        // lib.optionalAttrs osConfig.hardware.facter.detected.nvidia {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
        };

      home.packages = with pkgs; [
        app2unitPkg
        uwsm-game

        (xdg-utils.overrideAttrs (old: {
          postFixup =
            (old.postFixup or "")
            + ''
              rm $out/bin/xdg-open
              ln -s ${app2unit} $out/bin/xdg-open
            '';
        }))
      ];

      home.sessionVariables.GAMEMODERUNEXEC = "uwsm-game";

      programs.zsh.profileExtra = ''
        if uwsm check may-start; then
        	exec systemd-cat -t uwsm_start uwsm start default
        fi
      '';

      programs.alacritty.settings.terminal.shell = "${uwsm-shell}/bin/uwsm-shell";

      systemd.user.services = {
        swayidle.Service = {
          Type = lib.mkForce "exec";
          Slice = "background-graphical.slice";
        };
        waybar.Service = {
          Type = lib.mkForce "exec";
          Slice = "app-graphical.slice";
        };
        syncthingtray.Service.Slice = "background-graphical.slice";
        cliphist = {
          Service.Slice = "background-graphical.slice";
          Unit.After = ["graphical-session.target"];
        };
        cliphist-images = {
          Service.Slice = "background-graphical.slice";
          Unit.After = ["graphical-session.target"];
        };
        gammastep.Service.Slice = "background-graphical.slice";
      };
    };
  };

  den.aspects.home.uwsm.module = {
    homeManager = {config, ...}: {
      options.programs.uwsm = {
        environment = lib.mkOption {
          type = with lib.types;
            lazyAttrsOf (oneOf [
              str
              path
              int
              float
            ]);
          default = {};
        };
      };

      config = {
        xdg.configFile."uwsm/env".text = ''
          ${inputs.home-manager.lib.hm.shell.exportAll config.programs.uwsm.environment}
        '';
      };
    };
  };
}
