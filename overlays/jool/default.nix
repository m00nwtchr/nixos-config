{ ... }:
self: super:
with super;
let
  joolVersion = "4.1.15";

  # Fill this in with:
  #   nix store prefetch-file --unpack https://github.com/NICMx/Jool/releases/download/v4.1.15/jool-4.1.15.tar.gz
  joolSrc = fetchurl {
    url = "https://github.com/NICMx/Jool/releases/download/v${joolVersion}/jool-${joolVersion}.tar.gz";
    hash = "sha256-UWBLz2qff7uQgIdhAtBdoB3JHYxzzVgo/XPViVZD+M0=";
  };

  overrideJool =
    drv:
    drv.overrideAttrs (old: {
      version = joolVersion;
      src = joolSrc;
    });

  overrideKernelPackages =
    kp:
    kp.extend (
      kpSelf: kpSuper: {
        jool = overrideJool kpSuper.jool;
      }
    );
in
{
  # Userspace tools (jool, jool_siit, etc.)
  jool-cli = overrideJool super.jool-cli;

  # Kernel module package inside kernelPackages sets
  linuxPackages = overrideKernelPackages super.linuxPackages;
  linuxPackages_latest = overrideKernelPackages super.linuxPackages_latest;
  linuxPackages_6_6 = overrideKernelPackages super.linuxPackages_6_6;
  linuxPackages_hardened = overrideKernelPackages super.linuxPackages_hardened;

  # Add other kernelPackages variants you use here if needed.
}
