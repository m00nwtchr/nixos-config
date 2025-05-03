{
  config,
  lib,
  pkgs,
  inputs,
  system,
  osConfig,
  ...
}: {
  imports = [
    ./rust.nix
  ];

  home.packages = with pkgs; [
    # DevOps
    ansible
    kanidm

    gh # GitHub CLI

    # Kubernetes
    kubectl
    kubelogin-oidc
    kubernetes-helm
    cilium-cli
    k3d

    docker-compose

    lens

    mold # Linker
    lldb

    inputs.alejandra.defaultPackage.${system}

    # IDE
    jetbrains.idea-ultimate
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      nil
      helm-ls
      vscode-langservers-extracted
      yaml-language-server
    ];
    settings = {
      theme = "ayu_dark";
    };
    languages = let
      tabIndent = {
        tab-width = 4;
        unit = "\t";
      };
    in {
      language = [
        {
          name = "nix";
          indent = tabIndent;
          formatter = {
            name = "alejandra";
            command = "${inputs.alejandra.defaultPackage.${system}}/bin/alejandra";
          };
          auto-format = true;
        }

        {
          name = "cpp";
          indent = tabIndent;
          auto-format = true;
        }

        # Web
        {
          name = "html";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "html"];
          };
          auto-format = true;
        }
        {
          name = "json";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "json"];
          };
          auto-format = true;
        }
        {
          name = "css";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "css"];
          };
          auto-format = true;
        }
        {
          name = "javascript";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "typescript"];
          };
          auto-format = true;
        }
        {
          name = "typescript";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "typescript"];
          };
          auto-format = true;
        }
        {
          name = "tsx";
          indent = tabIndent;
          formatter = {
            name = "prettier";
            command = "${pkgs.nodePackages.prettier}/bin/prettier";
            args = ["--parser" "typescript"];
          };
          auto-format = true;
        }
      ];
    };
  };

  programs.git = {
    enable = true;
    userName = "m00nwtchr";
    userEmail = "m00nwtchr@duck.com";
    signing = {
      key = "0xDF3CEC6BF015D41D";
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

  services.podman = {
    enable = true;
    settings.storage.storage.driver = lib.mkForce osConfig.virtualisation.containers.storage.settings.storage.driver;
  };
}
