# Port of homes/x86_64-linux/m00n/env.nix — XDG paths, Java, NPM,
# Gradle, Cargo, RUSTUP, KUBECONFIG, etc. Declared as a sub-aspect
# `den.aspects.home.env`; included from the m00n user aspect's
# `homeManager.imports`.
{config, ...}: {
  den.aspects.home.env = {
    homeManager = {config, ...}: let
      inherit (config.home) homeDirectory;
      inherit (config.xdg) cacheHome configHome dataHome stateHome;
    in {
      home.sessionVariables = {
        # XDG base directories
        XDG_BIN_HOME = "${homeDirectory}/.local/bin";
        XDG_STATE_HOME = stateHome;

        # Development toolchains
        ANDROID_USER_HOME = "${dataHome}/android";
        ARDUINO_DIRECTORIES_DATA = "${dataHome}/arduino";
        CARGO_HOME = "${dataHome}/cargo";
        CUDA_CACHE_PATH = "${cacheHome}/nvidia";
        EM_CACHE = "${cacheHome}/emscripten/";
        EM_CONFIG = "${configHome}/emscripten/config";
        EM_PORTS = "${dataHome}/emscripten/";
        GOPATH = "${dataHome}/go";
        GRADLE_USER_HOME = "${dataHome}/gradle";
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        NVM_DIR = "${dataHome}/nvm";
        PNPM_HOME = "${dataHome}/pnpm";
        RUSTUP_HOME = "${dataHome}/rustup";
        _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${configHome}/java";

        # Infrastructure and networking
        ANSIBLE_HOME = "${cacheHome}/ansible";
        DOCKER_CONFIG = "${configHome}/docker";
        IPFS_GATEWAY = "http://localhost:8080";
        IPFS_PATH = "${dataHome}/ipfs";
        KREW_ROOT = "${stateHome}/krew";
        KUBECACHEDIR = "${cacheHome}/kube";
        KUBECONFIG = "${configHome}/kube/config";
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
        TALOSCONFIG = "${configHome}/talos/config";
        TPM2_PKCS_STORE = "${stateHome}/tpm2_pkcs11";

        # Application configuration and data
        IPYTHONDIR = "${configHome}/ipython";
        JUPYTER_CONFIG_DIR = "${configHome}/jupyter";
        MC_CONFIG_DIR = "${configHome}/mc";
        RECOLL_CONFDIR = "${stateHome}/recoll";
        RENPY_PATH_TO_SAVES = "${homeDirectory}/Documents/Games/RenPy";
        WGETRC = "${configHome}/wgetrc";
        WINEPREFIX = "${dataHome}/wineprefixes/default";

        # Interactive histories
        MYSQL_HISTFILE = "${stateHome}/mysql_history";
        NODE_REPL_HISTORY = "${stateHome}/node_repl_history";
        PYTHONHISTFILE = "${stateHome}/python_history";
        PSQL_HISTORY = "${stateHome}/psql_history";
        SQLITE_HISTORY = "${stateHome}/sqlite_history";
        VALKEYCLI_HISTFILE = "${stateHome}/valkeycli_history";

        # Desktop integration
        APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
        BROWSER = "librewolf";
        CALCULATOR = "gnome-calculator";

        # Diagnostics
        DEBUGINFOD_PROGRESS = "1";
      };

      home.sessionPath = with config.home.sessionVariables; [
        "${CARGO_HOME}/bin"
        "${KREW_ROOT}/bin"
        "${XDG_BIN_HOME}"
      ];
    };
  };
}
