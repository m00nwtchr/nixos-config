self: super:
with super; {
  safeeyes = safeeyes.overrideAttrs {
    preFixup = ''
      # Add swayidle to the PATH in addition to the existing utilities
      makeWrapperArgs+=(
        "''${gappsWrapperArgs[@]}"
        --prefix PATH : ${
        super.lib.makeBinPath [
          alsa-utils
          wlrctl
          xprintidle
          xorg.xprop
          swayidle # Add swayidle to the PATH
        ]
      }
      )
    '';
  };
}
