{pkgs, ...}: {
  environment.etc."systemd/system-sleep/wlan0-rfkill-networkctl".mode = "0755";
  environment.etc."systemd/system-sleep/wlan0-rfkill-networkctl".text = ''
    #!/bin/sh
    set -eu

    RFKILL="${pkgs.util-linux}/bin/rfkill"
    NETWORKCTL="${pkgs.systemd}/bin/networkctl"

    phase="$1"   # pre|post
    action="$2"  # suspend|hibernate|hybrid-sleep|suspend-then-hibernate

    log() {
      echo "[system-sleep][wlan0] $*" >&2
    }

    case "$phase" in
      pre)
        log "pre $action: rfkill block wifi"
        "$RFKILL" block wifi 2>/dev/null || true
        ;;
      post)
        log "post $action: rfkill unblock wifi"
        "$RFKILL" unblock wifi 2>/dev/null || true

        # Give the kernel/udev a moment to recreate/rename the interface after resume.
        # (Best-effort; don't block resume if it's slow.)
        i=0
        while [ "$i" -lt 20 ]; do
          if "$NETWORKCTL" status wlan0 >/dev/null 2>&1; then
            break
          fi
          i=$((i + 1))
          sleep 0.1
        done

        log "post $action: networkctl reload"
        "$NETWORKCTL" reload 2>/dev/null || true

        log "post $action: networkctl reconfigure wlan0"
        "$NETWORKCTL" reconfigure wlan0 2>/dev/null || true
        ;;
      *)
        ;;
    esac

    exit 0
  '';
}
