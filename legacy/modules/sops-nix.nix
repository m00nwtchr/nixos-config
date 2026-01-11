{
	config,
	inputs,
	lib,
	system,
	...
}: let
	defaultSopsPath = "${inputs.self}/systems/${system}/${config.networking.hostName}/secrets/default.yaml";
in {
	imports = [
		inputs.sops-nix.nixosModules.sops
	];

	sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

	sops.defaultSopsFile = lib.mkIf (builtins.pathExists defaultSopsPath) defaultSopsPath;
}
