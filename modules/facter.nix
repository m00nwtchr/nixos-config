{
	config,
	inputs,
	lib,
	...
}: let
	defaultFacterPath = "${inputs.self}/hosts/${config.networking.hostName}/facter.json";

	reportExists = builtins.pathExists defaultFacterPath;

	report =
		if config ? facter && reportExists
		then config.facter.report
		else {};
in {
	config.facter.reportPath = lib.mkIf reportExists defaultFacterPath;

	options.facter.detected.wireless =
		lib.mkEnableOption ""
		// {
			default =
				builtins.any
				(iface: (iface ? sub_class) && (iface.sub_class ? hex) && iface.sub_class.hex == "000a")
				(
					if report ? hardware && config.facter.report.hardware ? network_interface
					then report.hardware.network_interface
					else []
				);
		};

	options.facter.detected.isLaptop =
		lib.mkEnableOption ""
		// {
			default =
				if report ? hardware && report.hardware ? system && report.hardware.system ? form_factor
				then report.hardware.system.form_factor == "laptop"
				else false;
		};

	options.facter.detected.isDesktop =
		lib.mkEnableOption ""
		// {
			default =
				if report ? hardware && report.hardware ? system && report.hardware.system ? form_factor
				then report.hardware.system.form_factor == "desktop"
				else false;
		};

	options.facter.detected.nvidia =
		lib.mkEnableOption ""
		// {
			default =
				builtins.any (gpu: (gpu ? driver) && gpu.driver == "nvidia") (
					if report ? hardware && config.facter.report.hardware ? graphics_card
					then report.hardware.graphics_card
					else []
				);
		};
}
