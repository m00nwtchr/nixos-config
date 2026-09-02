# Port of homes/x86_64-linux/m00n/dev.nix — helix+langservers, git
# signing config, uv, dev tooling. Imports the rust + containers
# sub-aspects of the home.
{
  den,
  inputs,
  lib,
  __findFile ? __findFile,
  ...
}: {
  flake-file.inputs.alejandra = {
    url = "github:kamadorueda/alejandra/main";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.home.dev = {
    includes = [
      <home/rust>
      <home/containers>
      <home/ssh>
      <home/gpg>
      <home/autostart>
      <home/default>
      <home/wallust>
      <home/dunst>
      <home/waybar>
      <home/uwsm>
      <home/easyeffects>
      <home/kubeconfig>
    ];

    homeManager = {
      pkgs,
      inputs',
      ...
    }: {
      home.packages = with pkgs; [
        ansible
        kanidm_1_10

        gh
        git-filter-repo

        mold
        lldb
        clang

        arduino-ide
        android-studio
        jetbrains.idea
        jetbrains.pycharm
        zed-editor

        protobuf

        opencode

        alejandra
        vale

        cachix
        devenv
        shellcheck
        shfmt
      ];

      programs.helix = {
        enable = true;
        defaultEditor = true;

        extraPackages = with pkgs; [
          # nil
          helm-ls
          vscode-langservers-extracted
          yaml-language-server
          bash-language-server
        ];
        settings = {
          theme = "ayu_dark";
        };

        languages = {
          language-server = {
            rust-analyzer.config = {
              cargo.features = "all";
              check.command = "clippy";
              check.targets = [
                "x86_64-unknown-linux-gnu"
                "wasm32-unknown-unknown"
                "x86_64-linux-android"
              ];
            };
            sqls = {
              command = "${lib.getExe pkgs.sqls}";
            };
          };

          language = let
            tabIndent = {
              tab-width = 4;
              unit = "\t";
            };
          in [
            {
              name = "nix";
              indent = tabIndent;
              formatter = {
                name = "alejandra";
                command = "${lib.getExe inputs'.alejandra.packages.default}";
              };
              auto-format = true;
            }

            {
              name = "sql";
              indent = tabIndent;
              auto-format = true;
              language-servers = ["sqls"];
            }

            {
              name = "cpp";
              indent = tabIndent;
              auto-format = true;
            }

            {
              name = "html";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "html"];
              };
              auto-format = true;
            }
            {
              name = "json";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "json"];
              };
              auto-format = true;
            }
            {
              name = "css";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "css"];
              };
              auto-format = true;
            }
            {
              name = "javascript";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "typescript"];
              };
              auto-format = true;
            }
            {
              name = "typescript";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "typescript"];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "typescript"];
              };
              auto-format = true;
            }
            {
              name = "astro";
              indent = tabIndent;
              formatter = {
                name = "prettier";
                command = "${pkgs.prettier}/bin/prettier";
                args = ["--parser" "astro"];
              };
              auto-format = true;
            }
          ];
        };
      };

      programs.git = {
        enable = true;
        signing = {
          format = "openpgp";
          key = "0xDF3CEC6BF015D41D";
          signByDefault = true;
        };
        lfs.enable = true;
        settings = {
          user.name = "m00nwtchr";
          user.email = "m00n@naktis.eu";
          pull.rebase = false;
          init.defaultBranch = "master";
          submodule.recurse = true;
          push.autoSetupRemote = true;
          format.signoff = true;
        };
      };

      programs.uv.enable = true;

      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      };

      xdg.configFile."kanidm".text = ''
        uri = "https://idm.naktis.eu"
      '';

      m00n.kubeconfig = {
        enable = true;
        clusters.default = {
          "insecure-skip-tls-verify" = true;
          server = "https://ganymede:6443";
        };
        users.oidc = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1";
            command = "kubectl";
            args = [
              "oidc-login"
              "get-token"
              "--oidc-issuer-url=https://idm.naktis.eu/oauth2/openid/kubernetes"
              "--oidc-client-id=kubernetes"
              "--oidc-extra-scope=email"
              "--oidc-extra-scope=groups"
            ];
            env = null;
            interactiveMode = "Never";
            provideClusterInfo = false;
          };
        };
        contexts.default = {
          cluster = "default";
          user = "oidc";
        };
      };
    };
  };
}
