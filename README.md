# Want access? Open a PR adding yourself to users.nix

I'll grant access to well known members of the community, and people
well known members in the community trust.

# Notes

The deployed system has ***ZERO*** persistence. Do not store anything
on it that you want to keep. It will reboot from time to time and
lose everything on the hard drive.

# Configuring your computer for remote builds

First, put this in your `configuration.nix`:

```nix
{
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "aarch64.nixos.community";
        maxJobs = 96;
        sshKey = "/root/a-private-key";
        sshUser = "your-user-name";
        system = "aarch64-linux";
        supportedFeatures = [ "big-parallel" ];
      }
    ];
  };
}
```

Then run an initial SSH connection as root to setup the trust
fingerprint:


```
$ sudo su
# ssh your-user-name@aarch64.nixos.community -i /root/a-private-key
```

The fingerprint should always be:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds
```

***If it is not, please open an issue!***

Finally, `nix-build . -A hello --option system aarch64-linux`.

If this doesn't work, ping @grahamc and I can help debug.

---

Building: Make a `build.cfg` file:

```
buildHost       user@an-aarch64-capable-build-box
imageName       nixos-packet-aarch64-2018-01-03v1
pxeHost         user@web-accessible-server
pxeDir          /path/to/web/root
```

The build will happen on `buildHost` then SCPd directly from buildHost
to `pxeHost:pxeDir/imageName`. If this directory already exists, it
will be deleted.
