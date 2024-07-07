{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  inputs.nixos-infra = {
    url = "github:nixos/infra";
    flake = false;
  };
  inputs.ofborg.url = "github:nixos/ofborg";
  outputs = { nixpkgs, self, ofborg, nixos-infra }: {
    nixosConfigurations.aarch64-build-box = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        { ofborg.package = ofborg.packages.aarch64-linux.ofborg.rs; }
        { users.users.root.openssh.authorizedKeys.keys = (import "${nixos-infra}/ssh-keys.nix").infra; }
      ];
    };
    hydraJobs.system = self.nixosConfigurations.aarch64-build-box.config.system.build.toplevel;
  };
}
