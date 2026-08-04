# Port of homes/x86_64-linux/m00n/env.nix — XDG paths, Java, NPM,
# Gradle, Cargo, RUSTUP, KUBECONFIG, etc. Declared as a sub-aspect
# `den.aspects.home.env`; included from the m00n user aspect's
# `homeManager.imports`.
{config, ...}: {
  den.aspects.home.env = {
    homeManager = {config, ...}: {
      home.sessionVariables = {
        XDG_STATE_HOME = "${config.xdg.stateHome}";
        XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";

        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

        NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

        WGETRC = "${config.xdg.configHome}/wgetrc";

        GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
        CARGO_HOME = "${config.xdg.dataHome}/cargo";
        RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
        NVM_DIR = "${config.xdg.dataHome}/nvm";

        IPFS_PATH = "${config.xdg.dataHome}/ipfs";
        GOPATH = "${config.xdg.dataHome}/go";

        PNPM_HOME = "${config.xdg.dataHome}/pnpm";

        KUBECONFIG = "${config.xdg.configHome}/kube/config";
        KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
        KREW_ROOT = "${config.xdg.stateHome}/krew";

        ANSIBLE_HOME = "${config.xdg.cacheHome}/ansible";
        EM_CONFIG = "${config.xdg.configHome}/emscripten/config";
        EM_CACHE = "${config.xdg.cacheHome}/emscripten/";
        EM_PORTS = "${config.xdg.dataHome}/emscripten/";

        MC_CONFIG_DIR = "${config.xdg.configHome}/mc";

        WINEPREFIX = "${config.xdg.dataHome}/wineprefixes/default";

        RENPY_PATH_TO_SAVES = "${config.home.homeDirectory}/Documents/Games/RenPy";

        MYSQL_HISTFILE = "${config.xdg.stateHome}/mysql_history";
        NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
        PYTHONHISTFILE = "${config.xdg.stateHome}/python_history";
        SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite_history";

        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nvidia";

        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";

        TPM2_PKCS_STORE = "${config.xdg.stateHome}/tpm2_pkcs11";

        DEBUGINFOD_PROGRESS = "1";

        IPFS_GATEWAY = "http://localhost:8080";

        BROWSER = "librewolf";
        CALCULATOR = "gnome-calculator";

        RECOLL_CONFDIR = "${config.xdg.stateHome}/recoll";
        APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
      };

      home.sessionPath = with config.home.sessionVariables; [
        "${KREW_ROOT}/bin"
        "${config.home.homeDirectory}/.local/bin"
      ];
    };
  };
}
