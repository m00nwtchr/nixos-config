#!/usr/bin/env bash

set -euo pipefail

########## 1. AppID ###########################################################
APPID="${SteamAppId:-${SteamGameId:-}}"

########## 2. Locate manifest #################################################
manifest_path=""
if [[ -n "$APPID" ]]; then
	# Prefer STEAM_COMPAT_LIBRARY_PATHS if present
	if [[ -n "${STEAM_COMPAT_LIBRARY_PATHS:-}" ]]; then
		IFS=':' read -ra paths <<< "$STEAM_COMPAT_LIBRARY_PATHS"
		for p in "${paths[@]}"; do
			test -f "$p/appmanifest_${APPID}.acf" && { manifest_path="$p/appmanifest_${APPID}.acf"; break; }
		done
	fi

	# Fallback: walk up from install dir / PWD
	if [[ -z "$manifest_path" ]]; then
		dir="${STEAM_COMPAT_INSTALL_PATH:-$PWD}"
		while [[ "$dir" != "/" ]]; do
			if [[ "$(basename "$dir")" == "steamapps" ]] && [[ -f "$dir/appmanifest_${APPID}.acf" ]]; then
				manifest_path="$dir/appmanifest_${APPID}.acf"
				break
			fi
			dir="$(dirname "$dir")"
		done
	fi
fi

########## 3. Parse manifest ##################################################
parse_field() {
	sed -nE 's/^[[:space:]]*"'$1'"[[:space:]]*"([^"]*)".*/\1/p' "$manifest_path" | head -n1
}

NAME=""
if [[ -n "$manifest_path" ]]; then
	NAME=$(parse_field "name")
fi

########## 4. Log #############################################################
LOG="$HOME/steam_wrapper.log"
{
	echo "[$(date)] Launching: ${NAME:-<unknown>}"
	echo "	AppID:       ${APPID:-<unset>}"
	echo "	Command:     $*"
	echo "	Manifest:    ${manifest_path:-<none found>}"
	echo "---"
} >> "$LOG"

########## 5. Hand off ########################################################
if [[ -n "$NAME" ]]; then
	exec app2unit -a "$NAME" -d "$NAME" -- "$@"
else
	# No Steam env or name detected — just call app2unit bare
	exec app2unit -- "$@"
fi
