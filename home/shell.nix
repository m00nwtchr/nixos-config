{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ssh.nix
    ./gpg.nix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = false;
  };

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initExtraFirst = ''
      (cat ${config.xdg.cacheHome}/wallust/sequences &)

      eval "$(${lib.getExe pkgs.direnv} hook zsh)"

      if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh" ]]; then
       source "${config.xdg.cacheHome}/p10k-instant-prompt-${config.home.username}.zsh"
      fi
    '';

    completionInit = ''
      zstyle :compinstall filename "$ZDOTDIR/zshrc"
      zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/zcompcache"
      autoload -U compinit && compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
    '';

    initExtra = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"
    '';

    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };
    history = {
      size = 10000;
      path = "${config.xdg.stateHome}/zsh/history";
    };
  };

  home.packages = with pkgs; [
    zsh-powerlevel10k

    ripgrep
    jq
    yq-go

    # archives
    zip
    unzip
    xz
    p7zip
    gnutar
    zstd

    # networking tools
    ldns
    socat
    nmap

    # utils
    file
    which
    tree
    gnused
    gawk

    nix-output-monitor

    # system call monitoring
    strace
    ltrace
    lsof

    # system tools
    neofetch
    htop
    iotop # io monitoring
    iftop # network monitoring
    powertop

    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];

  # programs.helix = {
  #   enable = true;
  #   settings = {
  #     languages.language = [
  #       {
  #         name = "nix";
  #         auto-format = true;
  #         formatter.command = "${pkgs.alejandra}/bin/alejandra";
  #       }
  #     ];
  #   };
  # };
}
