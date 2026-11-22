{...}: {
  perSystem = {pkgs, ...}: let
    mkAppImage = {
      pname,
      version,
      src,
      extraPkgs ? pkgs: [],
    }: let
      contents = pkgs.appimageTools.extract {
        inherit pname version src;
      };
    in
      pkgs.appimageTools.wrapType2 {
        inherit pname version src extraPkgs;

        extraInstallCommands = ''
          # Install the upstream desktop entry.
          desktop="$(find "${contents}" -maxdepth 1 \
            -name '*.desktop' -print -quit)"

          if [ -z "$desktop" ]; then
            echo "AppImage has no desktop entry" >&2
            exit 1
          fi

          desktop_file="$out/share/applications/$(basename "$desktop")"
          install -Dm644 "$desktop" "$desktop_file"

          # Point the desktop entry at the Nix wrapper.
          sed -i -E \
            's|^Exec=[^[:space:]]+|Exec=${pname}|' \
            "$desktop_file"

          # Preserve upstream icon themes.
          if [ -d "${contents}/usr/share/icons" ]; then
            mkdir -p "$out/share/icons"
            cp -r --no-preserve=mode \
              "${contents}/usr/share/icons/." \
              "$out/share/icons/"
          fi

          # Resolve the icon referenced by the desktop entry.
          icon_name="$(sed -n '/^Icon=/{s/^Icon=//;p;q;}' "$desktop")"
          icon=""

          if [ -n "$icon_name" ]; then
            # Prefer a matching root-level icon.
            for ext in png svg xpm; do
              candidate="${contents}/$icon_name.$ext"

              if [ -f "$candidate" ]; then
                icon="$candidate"
                break
              fi
            done

            # Fall back to .DirIcon.
            if [ -z "$icon" ] && [ -f "${contents}/.DirIcon" ]; then
              icon="${contents}/.DirIcon"
            fi

            # Install into the hicolor icon theme.
            if [ -n "$icon" ]; then
              format="$(${pkgs.imagemagick}/bin/identify \
                -ping -format '%m' "$icon")"

              case "$format" in
                SVG)
                  ext=svg
                  size=scalable
                  ;;
                PNG|XPM)
                  ext="$(echo "$format" | tr '[:upper:]' '[:lower:]')"
                  size="$(${pkgs.imagemagick}/bin/identify \
                    -ping -format '%wx%h' "$icon")"
                  ;;
                *)
                  echo "Unsupported icon format: $format" >&2
                  exit 1
                  ;;
              esac

              install -Dm644 "$icon" \
                "$out/share/icons/hicolor/$size/apps/$icon_name.$ext"
            fi
          fi
        '';

        meta.mainProgram = pname;
      };
  in {
    packages.duckstation = mkAppImage {
      pname = "duckstation";
      version = "2026-10-13";

      src = pkgs.fetchurl {
        url = "https://github.com/stenzek/duckstation/releases/download/latest/DuckStation-x64.AppImage";
        hash = "sha256-xebwRfaiQggvyvqfAtVq2JXiM7lCcoeI0jKtDAx2XCQ=";
      };
    };
  };
}
