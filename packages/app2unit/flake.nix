{
  description = "Flake wrapping app2unit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    app2unit-src = {
      url = "github:Vladimir-csp/app2unit";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      app2unit-src,
    }:
    let
      mkPkg =
        pkgs:
        pkgs.stdenv.mkDerivation {
          pname = "app2unit";
          version = "1.0";

          src = app2unit-src;

          installPhase = ''
            mkdir -p $out/bin
            install -m 755 $src/app2unit $out/bin/app2unit
            ln -s $out/bin/app2unit $out/bin/app2unit-open
          '';

          meta = with pkgs.lib; {
            description = "Utility script for managing application-to-systemd unit conversions.";
            homepage = "https://github.com/Vladimir-csp/app2unit";
            license = licenses.gpl3;
            maintainers = with maintainers; [ ];
          };
        };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        app2unit = mkPkg pkgs;
      in
      {
        packages.default = app2unit;
        apps.default = flake-utils.lib.mkApp {
          drv = app2unit;
        };
      }
    )
    // {
      overlays.default = final: prev: { app2unit = mkPkg prev; };
    };
}
