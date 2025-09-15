{
  config,
  lib,
  pkgs,
  ...
}: let
  uwsm-shell = pkgs.writeShellScriptBin "uwsm-shell" ''
    exec ${pkgs.app2unit}/bin/app2unit -- $(getent passwd $USER | cut -d: -f7)
  '';

  uwsm-game = pkgs.writeShellScriptBin "uwsm-game" (builtins.readFile ./bin/uwsm-game.sh);
in {
  xdg.configFile."uwsm/env".text = ''
    source "$HOME/scripts/funcs"
    if ifmod nvidia_drm; then
    	export GBM_BACKEND=nvidia-drm
    	export __GLX_VENDOR_LIBRARY_NAME=nvidia
    	export LIBVA_DRIVER_NAME=nvidia
    	#export WLR_NO_HARDWARE_CURSORS=1
    	#export XWAYLAND_NO_GLAMOR=1
    	#export WLR_RENDERER=vulkan
    fi

    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export QT_QPA_PLATFORMTHEME=qt6ct

    export _JAVA_AWT_WM_NONREPARENTING=1
    export XCURSOR_SIZE=24

    export MOZ_ENABLE_WAYLAND=1
    export ECORE_EVAS_ENGINE=wayland_egl
    export ELM_ENGINE=wayland_egl
    export SDL_VIDEODRIVER=wayland
    export SDL_AUDIODRIVER=pipewire
  '';

  home.packages = with pkgs; [
    app2unit
    uwsm-game

    (xdg-utils.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + ''
          rm $out/bin/xdg-open
          ln -s ${pkgs.app2unit}/bin/app2unit $out/bin/xdg-open
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
      Slice = "background-graphical.slice"; # Assign to UWSM slice
    };
    waybar.Service = {
      Type = lib.mkForce "exec";
      Slice = "app-graphical.slice"; # Assign to UWSM slice
    };
    syncthingtray.Service.Slice = "background-graphical.slice";
    cliphist = {
      Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
      Unit.After = ["graphical-session.target"];
    };
    cliphist-images = {
      Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
      Unit.After = ["graphical-session.target"];
    };
    # wluma.Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
    gammastep.Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
  };
}
