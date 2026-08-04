{
  config,
  self,
  lib,
  pkgs,
  ...
}: {
  den.aspects.home.shell = {
    homeManager = {
      pkgs,
      config,
      osConfig,
      ...
    }: {
      home.packages = with pkgs; [
        zsh-powerlevel10k

        sops

        ripgrep
        jq
        yq-go

        zip
        unzip
        xz
        p7zip
        gnutar
        zstd

        ldns
        socat
        nmap

        file
        which
        tree
        gnused
        gawk

        nix-output-monitor

        strace
        ltrace
        lsof

        fastfetch
        htop
        iotop
        iftop
        powertop

        sysstat
        lm_sensors
        ethtool
        pciutils
        usbutils
      ];

      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          size = 10000;
          path = "${config.xdg.stateHome}/zsh/history";
        };

        initContent = let
          p10k = builtins.path {
            path = ../../../home/m00n/zsh/p10k.zsh;
            name = "p10k.zsh";
          };
        in
          lib.mkMerge [
            (lib.mkBefore
              ''
                (cat ${config.xdg.cacheHome}/wallust/sequences &)

                eval "$(${lib.getExe pkgs.devenv} hook zsh)"

                if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh" ]]; then
                  source "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh"
                fi
              '')

            ''
              function set_window_title() {
                print -Pn "\e]0;$TERM - %n@%m: %~\a"
              }

              autoload -Uz add-zsh-hook
              add-zsh-hook chpwd set_window_title
              set_window_title
            ''

            ''
              source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
              source ${p10k}
            ''
          ];

        completionInit = ''
          zstyle :compinstall filename "$ZDOTDIR/zshrc"
          zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
          autoload -U compinit && compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
        '';

        shellAliases = {
          ll = "ls -l";
          update = "sudo nixos-rebuild switch";
        };

        siteFunctions = {
          kpatch_all_ns = builtins.readFile ../../../home/m00n/zsh/site-functions/kpatch_all_ns.zsh;
          _kpatch_all_ns = builtins.readFile ../../../home/m00n/zsh/site-functions/_kpatch_all_ns.zsh;
        };
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = false;
      };

      programs.atuin = {
        enable = true;
        settings = {
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "https://atuin.m00nlit.dev";
          search_mode = "fuzzy";

          key_path = osConfig.sops.secrets."atuin_key".path;
          session_path = osConfig.sops.secrets."atuin/session".path;
        };
      };
    };
  };
}
