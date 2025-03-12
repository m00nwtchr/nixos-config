{
  config,
  lib,
  pkgs,
  system,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # mold # Linker
    # sccache

    inputs.alejandra.defaultPackage.${system}
    rust-bin.stable.latest.default
    rust-bin.stable.latest.rust-src
    rust-bin.stable.latest.rust-analyzer
    # rust-bin.stable.latest.rustfmt

    # IDE
    jetbrains.rust-rover
  ];

  home.sessionVariables = {
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.llvmPackages.clangUseLLVM}/bin/clang";
    RUSTFLAGS = "-Clink-arg=-fuse-ld=${pkgs.mold}/bin/mold";
  };
}
