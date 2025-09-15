{
  config,
  lib,
  pkgs,
  system,
  ...
}:
{
  home.packages = with pkgs; [
    # mold # Linker
    # sccache

    # (rust-bin.stable.latest.default.override {
    #   extensions = ["rust-src" "rust-analyzer"];
    # })

    # IDE
    jetbrains.rust-rover
  ];

  home.sessionVariables = {
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };

  programs.helix.languages.language = [
    {
      name = "rust";
      debugger = {
        name = "lldb-dap";
        transport = "stdio";
        command = "${pkgs.lldb}/bin/lldb-dap";

        templates = [
          {
            name = "binary";
            request = "launch";
            completion = [
              {
                name = "binary";
                completion = "filename";
              }
            ];
            args =
              let
                lldbScript = pkgs.writeText "lldb_vscode_rustc_primer.py" ''
                  import subprocess
                  import pathlib
                  import lldb

                  # Determine the sysroot for the active Rust interpreter
                  rustlib_etc = pathlib.Path(subprocess.getoutput('rustc --print sysroot')) / 'lib' / 'rustlib' / 'etc'
                  if not rustlib_etc.exists():
                      raise RuntimeError('Unable to determine rustc sysroot')

                  # Load lldb_lookup.py and execute lldb_commands with the correct path
                  lldb.debugger.HandleCommand(f"""command script import "{rustlib_etc / 'lldb_lookup.py'}" """)
                  lldb.debugger.HandleCommand(f"""command source -s 0 "{rustlib_etc / 'lldb_commands'}" """)
                '';
              in
              {
                program = "{0}";
                initCommands = [
                  "command script import ${lldbScript}"
                ];
              };
          }
        ];
      };
    }
  ];
}
