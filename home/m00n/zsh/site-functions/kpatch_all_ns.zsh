#autoload
emulate -L zsh
setopt pipefail

local kind="$1"
local patch_json="$2"

if [[ -z "$kind" || -z "$patch_json" ]]; then
	print -u2 "Usage: kpatch_all_ns <objectType> <mergeJson>"
	print -u2 'Example: kpatch_all_ns replicationdestination '\''{"spec":{"paused":true}}'\'''
	return 2
fi

kubectl get "$kind" -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}' \
	| while IFS=$'\t' read -r ns name; do
		[[ -z "$ns" || -z "$name" ]] && continue
		kubectl -n "$ns" patch "$kind" "$name" --type=merge -p "$patch_json"
	done

