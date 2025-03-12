{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./rust.nix
  ];

  home.packages = with pkgs; [
    # DevOps
    ansible
    kanidm

    # Kubernetes
    kubectl
    kubelogin-oidc
    kubernetes-helm

    lens

    # Helix LS
    nil
    helm-ls

    gh # GitHub CLI
    mold # Linker

    # IDE
    jetbrains.idea-ultimate
  ];

  programs.git = {
    enable = true;
    userName = "m00nwtchr";
    userEmail = "m00nwtchr@duck.com";
    signing = {
      key = "0x800214724BE3A82F";
      signByDefault = true;
    };
    lfs.enable = true;
    extraConfig = {
      pull.rebase = false;
      init.defaultBranch = "master";
      submodule.recurse = true;
      push.autoSetupRemote = true;
    };
  };
}
