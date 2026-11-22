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
  flake-file.inputs.alejandra.url = "github:kamadorueda/alejandra/main";

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
      <dev/unity>
    ];

    homeManager = {
      pkgs,
      inputs',
      ...
    }: {
      home.packages = with pkgs; [
        ansible
        kanidm_1_11

        gh
        git-filter-repo

        mold
        lldb
        clang

        arduino-ide
        # android-studio
        android-tools

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
          sqls
          inputs'.alejandra.packages.default

          markdown-oxide

          tinymist
          # vale-ls
          harper
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
              command = "sqls";
            };

            # vale.command = "vale-ls";
            harper = {
              command = "harper-ls";
              args = ["--stdio"];
              config.harper-ls = {
                dialect = "British";
              };
            };
          };

          language = let
            tabIndent = {
              tab-width = 4;
              unit = "\t";
            };
          in [
            {
              name = "typst";
              language-servers = ["tinymist" "harper"];
              auto-format = true;
            }
            {
              name = "markdown";
              language-servers = ["marksman" "markdown-oxide" "harper"];
              auto-format = true;
            }

            {
              name = "nix";
              indent = tabIndent;
              formatter = {
                name = "alejandra";
                command = "alejandra";
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
              name = "json";
              # indent = tabIndent;
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
              "--token-cache-storage=keyring"
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
