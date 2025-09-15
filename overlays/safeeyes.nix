self: super: with super; {
  safeeyes = safeeyes.overrideAttrs {
    # Configure safeeyes for Wayland.
    preFixup = ''
      makeWrapperArgs+=(
        "''${gappsWrapperArgs[@]}"
        --prefix PATH : ${
          super.lib.makeBinPath [
            alsa-utils
            wlrctl
            swayidle
          ]
        }
      )
    '';
  };
}
