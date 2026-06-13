# Port of hosts/tide/rfkill-${interface}.nix — sleep hook that rfkill-blocks
# wifi before sleep and unblocks + networkctl reload after.
{pkgs, ...}: {
  den.aspects.system.rfkill = interface: {
    name = "rfkill/${interface}";
    nixos = {pkgs, ...}: {
      environment.etc."systemd/system-sleep/00-${interface}-rfkill-networkctl" = {
        mode = "0755";
        text = ''
          #!/bin/sh
          set -eu

          RFKILL="${pkgs.util-linux}/bin/rfkill"
          NETWORKCTL="${pkgs.systemd}/bin/networkctl"
          INTERFACE="${interface}"

          phase="$1"  # pre|post
          action="$2" # suspend|hibernate|hybrid-sleep|suspend-then-hibernate

          log() {
            echo "[system-sleep][$INTERFACE] $*" >&2
          }

          case "$phase" in
          pre)
            log "pre $action: rfkill block wifi"
            "$RFKILL" block wifi 2>/dev/null || true
            ;;
          post)
            log "post $action: rfkill unblock wifi"
            "$RFKILL" unblock wifi 2>/dev/null || true

            i=0
            while [ "$i" -lt 20 ]; do
              if "$NETWORKCTL" status "$INTERFACE" >/dev/null 2>&1; then
                break
              fi
              i=$((i + 1))
              sleep 0.1
            done

            log "post $action: networkctl reload"
            "$NETWORKCTL" reload 2>/dev/null || true

            log "post $action: networkctl reconfigure $INTERFACE"
            "$NETWORKCTL" reconfigure "$INTERFACE" 2>/dev/null || true
            ;;
          *)
            ;;
          esac

          exit 0
        '';
      };
    };
  };
}
