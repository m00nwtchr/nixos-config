{
	stdenv,
	lib,
	fetchFromGitHub,
	...
}:
stdenv.mkDerivation rec {
	pname = "app2unit";
	version = "1.2.1";

	src =
		fetchFromGitHub {
			owner = "Vladimir-csp";
			repo = "app2unit";
			rev = "v${version}";
			sha256 = "0sismfz5wpjy8cx01mm90kx59bglab42ngpd42iljfd05knid78d";
		};

	dontBuild = true;
	installPhase = ''
		mkdir -p $out/bin
		install -m 755 $src/app2unit $out/bin/app2unit
		ln -s $out/bin/app2unit $out/bin/app2unit-open
	'';

	meta = with lib; {
		description = "Utility script for managing application-to-systemd unit conversions.";
		homepage = "https://github.com/Vladimir-csp/app2unit";
		license = licenses.gpl3;
		maintainers = with maintainers; [];
	};
}
