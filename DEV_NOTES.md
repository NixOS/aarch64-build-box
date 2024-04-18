# How to build community build box

```
nix build .#hydraJobs.system
```

You will need to be on an aarch64-linux machine or have an
aarch64-linux builder configured.

You can use
[nix-netboot-serve](https://github.com/DeterminateSystems/nix-netboot-serve/)
to provide netboot for the resulting configuration.

(TODO: this isn't implemented yet)
The production machine boots via the [build on hydra.nixos.org](TODO)
using netboot.nixos.org, which is also running nix-netboot-serve.

