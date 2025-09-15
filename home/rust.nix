{
	config,
	lib,
	pkgs,
	system,
	...
}: {
	home.packages = with pkgs; [
		# IDE
		(jetbrains.rust-rover.override {
				jdk = pkgs.openjdk21;
			})
	];

	home.sessionVariables = {
		RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
	};

	# home.file.".cargo/config.toml".text = ''
	#   [target.x86_64-unknown-linux-gnu]
	#   linker = "clang"
	#   rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
	# '';

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
						args = let
							lldbScript =
								pkgs.writeText "lldb_vscode_rustc_primer.py" ''
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
						in {
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
