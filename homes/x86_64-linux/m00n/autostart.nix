{
	config,
	pkgs,
	...
}: {
	home.packages = with pkgs; [
		safeeyes
	];

	xdg.configFile."autostart/io.github.slgobinath.SafeEyes.desktop".source = "${pkgs.safeeyes}/share/applications/io.github.slgobinath.SafeEyes.desktop";
	xdg.configFile."systemd/user/app-io.github.slgobinath.SafeEyes@autostart.service.d/override.conf".text = ''
		[Unit]
		Requires=tray.target
		After=tray.target
	'';
}
