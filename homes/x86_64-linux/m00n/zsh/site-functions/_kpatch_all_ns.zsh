#compdef kpatch_all_ns
emulate -L zsh

# Cache for this shell session
typeset -ga _kpatch_all_ns_resources

_kpatch_all_ns__load_resources() {
	# Only populate once per session
	(( ${#_kpatch_all_ns_resources} > 0 )) && return 0

	local name short group s
	while IFS=$'\t' read -r name short group; do
		[[ -z "$name" ]] && continue

		# NAME
		_kpatch_all_ns_resources+=("$name")

		# SHORTNAMES (comma-separated)
		if [[ -n "$short" && "$short" != "<none>" ]]; then
			for s in ${(s:,:)short}; do
				[[ -n "$s" ]] && _kpatch_all_ns_resources+=("$s")
			done
		fi

		# Fully-qualified: name.group
		if [[ -n "$group" && "$group" != "<none>" ]]; then
			_kpatch_all_ns_resources+=("${name}.${group}")
		fi
	done < <(
		kubectl api-resources --cached=false --verbs=list -o wide 2>/dev/null \
			| tail -n +2 \
			| awk '{print $1"\t"$2"\t"$3}'
	)

	# Deduplicate
	_kpatch_all_ns_resources=(${(u)_kpatch_all_ns_resources})
}

# Arg 1: resource type
if (( CURRENT == 2 )); then
	_kpatch_all_ns__load_resources
	_describe -t kuberesources 'kubernetes resource' _kpatch_all_ns_resources
	return
fi

# Arg 2: merge patch JSON (free-form), but offer a few useful presets
if (( CURRENT == 3 )); then
	local -a patches
	patches=(
		'{"spec":{"paused":true}}:set spec.paused true'
		'{"spec":{"paused":false}}:set spec.paused false'
		'{"metadata":{"annotations":{"paused":"true"}}}:add paused annotation'
	)
	_describe -t jsonpatch 'merge patch' patches
	return
fi
