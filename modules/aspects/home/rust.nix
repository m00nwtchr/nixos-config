# Port of homes/x86_64-linux/m00n/rust.nix — rust-rover IDE +
# sccache + mold linker.
{
  ...
}: {
  den.aspects.home.rust = {
    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        jetbrains.rust-rover
      ];

      home.sessionVariables.RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";

      home.file.".cargo/config.toml".text = ''
        [target.x86_64-unknown-linux-gnu]
        linker = "clang"
        rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
      '';
    };
  };
}
