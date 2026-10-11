{...}: {
  perSystem = {pkgs, ...}: {
    packages.waybar-modules = pkgs.rustPlatform.buildRustPackage {
      pname = "waybar-modules";
      version = "0.1.0";

      src = ./.;
      cargoLock.lockFile = ./Cargo.lock;

      meta.mainProgram = "waybar-modules";
    };
  };
}
