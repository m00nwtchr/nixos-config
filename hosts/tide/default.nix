# Per-host data file for tide. In the den pattern, this file
# provides host-specific data that downstream aspect modules can
# read via the {host} context arg (or `den.lib.__findFile` for
# path-based lookups against `hosts/<host.name>/...`).
#
# Source equivalent: systems/x86_64-linux/tide/default.nix
# In the source, this file imports many legacy modules. In the
# den port, the actual NixOS configuration lives in
# `modules/aspects/hosts/tide.nix` (the host aspect). This file is
# just a data anchor — den treats each subdirectory of `hosts/`
# as a host entity.
{ ... }:
{
  # No additional data yet; everything in tide's NixOS config is
  # expressed via the host aspect in modules/aspects/hosts/tide.nix.
  # This file exists to anchor tide as a den entity. Add per-host
  # data attrs here as the port grows.
}
