# Port of homes/x86_64-linux/m00n/dev.nix — helix+langservers, git
# signing config, uv, dev tooling. Imports the rust + containers
# sub-aspects of the home.
{
  den,
  inputs,
  lib,
  __findFile ? __findFile,
  ...
}: {
  den.aspects.dev.unity = {
    os.nixpkgs.overlays = [
      (final: prev: let
        extra-path = with final; [
          dotnetCorePackages.sdk_8_0
          dotnetPackages.Nuget
          mono
          # msbuild
        ];

        extra-lib = with final; [
          # Personal development stuff
          libx11

          # Rider Unity debugging
          libxcursor
          libxrandr
          libglvnd
        ];

        rider = prev.jetbrains.rider.overrideAttrs (attrs: {
          postInstall =
            (attrs.postInstall or "")
            + ''
              # Wrap rider with extra tools and libraries
              mv $out/bin/rider $out/bin/.rider-toolless
              makeWrapper $out/bin/.rider-toolless $out/bin/rider \
                --argv0 rider \
                --prefix PATH : "${lib.makeBinPath extra-path}" \
                --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath extra-lib}"

              # Making Unity Rider plugin work!
              # The plugin expects the binary to be at /rider/bin/rider, with bundled files at /rider/
              # It does this by going up one directory from the directory the binary is in
              # We have rider binary at $out/bin/rider, so we need to link /rider/ to $out/
              shopt -s extglob
              ln -s $out/rider/!(bin) $out/
              shopt -u extglob
            '';
        });
      in {
        jetbrains =
          prev.jetbrains
          // {
            inherit rider;
          };

        unityhub = prev.unityhub.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              wrapProgram $out/opt/unityhub/unityhub \
                --prefix LD_LIBRARY_PATH : "${final.ncurses}/lib"
            '';
        });
      })
    ];

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.activation.unityShaderCompilerLibtinfoFix = lib.hm.dag.entryAfter ["writeBoundary"] ''
        shopt -s nullglob
        for tools in "$HOME"/Unity/Hub/Editor/*/Editor/Data/Tools; do
          libDir="$tools/../lib"
          run mkdir -p "$libDir"
          run ln -sf "${pkgs.ncurses}/lib/libtinfo.so.6" "$libDir/libtinfo.so.6"
        done
      '';

      home.packages = with pkgs; [
        unityhub
        # jetbrains.rider
      ];

      #   home.file.".local/share/applications/jetbrains-rider.desktop".source = let
      #     desktopFile = pkgs.makeDesktopItem {
      #       name = "jetbrains-rider";
      #       desktopName = "Rider";
      #       exec = "\"${pkgs.jetbrains.rider}/bin/rider\"";
      #       icon = "rider";
      #       type = "Application";
      #       # Don't show desktop icon in search or run launcher
      #       extraConfig.NoDisplay = "true";
      #     };
      #   in "${desktopFile}/share/applications/jetbrains-rider.desktop";
    };
  };
}
