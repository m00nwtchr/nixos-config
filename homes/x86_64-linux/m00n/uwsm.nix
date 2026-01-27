{
	config,
	osConfig,
	lib,
	pkgs,
	inputs,
	namespace,
	...
}: let
	uwsm-shell =
		pkgs.writeShellScriptBin "uwsm-shell" ''
			exec ${pkgs.app2unit}/bin/app2unit -- $(getent passwd $USER | cut -d: -f7)
		'';

	uwsm-game = pkgs.writeShellScriptBin "uwsm-game" (builtins.readFile ./bin/uwsm-game.sh);
in {
	imports = [
		./modules/uwsm.nix
	];

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
		// lib.optionalAttrs osConfig.${namespace}.hardware.facter.detected.nvidia {
			GBM_BACKEND = "nvidia-drm";
			__GLX_VENDOR_LIBRARY_NAME = "nvidia";
			LIBVA_DRIVER_NAME = "nvidia";
			# WLR_NO_HARDWARE_CURSORS=1;
			# XWAYLAND_NO_GLAMOR=1;
		};

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
