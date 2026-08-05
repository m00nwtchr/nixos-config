# nixos-config

My nixos configuration, automatically converted from the version I manually wrote using snowfall lib (`old` branch).

## NH / VM

```console
# default action is build
nix run .#tide

# pass any other nh action
nix run .#tide -- switch
```

### Run the VM

```console
nix run .#vm
```
