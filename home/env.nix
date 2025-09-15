{
  config,
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    XDG_STATE_HOME = "${config.xdg.stateHome}";
    XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";

    ######################################################################
    # Java Configuration
    ######################################################################
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

    ######################################################################
    # Node Package Manager (NPM)
    ######################################################################
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

    ######################################################################
    # Wget Configuration
    ######################################################################
    WGETRC = "${config.xdg.configHome}/wgetrc";

    ######################################################################
    # Build Tools and Package Managers
    ######################################################################
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    NVM_DIR = "${config.xdg.dataHome}/nvm";

    ######################################################################
    # IPFS and Go
    ######################################################################
    IPFS_PATH = "${config.xdg.dataHome}/ipfs";
    GOPATH = "${config.xdg.dataHome}/go";

    ######################################################################
    # Additional Package Managers
    ######################################################################
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";

    ######################################################################
    # Kubernetes Configuration
    ######################################################################
    KUBECONFIG = "${config.xdg.configHome}/kube/config";
    KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
    KREW_ROOT = "${config.xdg.stateHome}/krew";

    ######################################################################
    # Ansible and Emscripten
    ######################################################################
    ANSIBLE_HOME = "${config.xdg.cacheHome}/ansible";
    EM_CONFIG = "${config.xdg.configHome}/emscripten/config";
    EM_CACHE = "${config.xdg.cacheHome}/emscripten/";
    EM_PORTS = "${config.xdg.dataHome}/emscripten/";

    ######################################################################
    # Wine Configuration
    ######################################################################
    WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";

    ######################################################################
    # Ren'Py Game Saves
    ######################################################################
    RENPY_PATH_TO_SAVES = "${config.home.homeDirectory}/Documents/Games/RenPy";

    ######################################################################
    # Command History Files
    ######################################################################
    MYSQL_HISTFILE = "${config.xdg.stateHome}/mysql_history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
    PYTHONHISTFILE = "${config.xdg.stateHome}/python_history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite_history";

    ######################################################################
    # CUDA and GPU Cache
    ######################################################################
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nvidia";

    ######################################################################
    # GPG, SSH, and Miscellaneous
    ######################################################################
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";

    ######################################################################
    # TPM2 Configuration
    ######################################################################
    TPM2_PKCS_STORE = "${config.xdg.stateHome}/tpm2_pkcs11";

    ######################################################################
    # Debug Information
    ######################################################################
    DEBUGINFOD_PROGRESS = "1";

    ######################################################################
    # IPFS Gateway
    ######################################################################
    IPFS_GATEWAY = "http://localhost:8080";

    ######################################################################
    # Application Paths and Defaults
    ######################################################################
    BROWSER = "librewolf";
    CALCULATOR = "gnome-calculator";

    RECOLL_CONFDIR = "${config.xdg.stateHome}/recoll";
    APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
}
