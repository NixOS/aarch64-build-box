{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  inputs.ofborg.url = "github:nixos/ofborg";
  outputs = { nixpkgs, self, ofborg }: {
    nixosConfigurations.aarch64-build-box = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        { ofborg.package = ofborg.packages.aarch64-linux.ofborg.rs; }
      ];
    };
    hydraJobs.system = self.nixosConfigurations.aarch64-build-box.config.system.build.toplevel;
  };
}
