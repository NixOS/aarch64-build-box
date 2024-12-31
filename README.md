# 🚫 Unavailable as of 2024-12-31 🚫

At 18:30 UTC we shut down all machines that were sponsored by Equinix Metal, since the sponsoring relationship is coming to an end.

Whether we can provide this service again in the future is up for discussion and possibly funding.

# <del>Want access?</del>

1. <del>You must read literally this entire README. It is critically
   important that you do so.</del>
2. <del>Open a PR adding yourself to users.nix</del>

<del>I'll grant access to well known members of the community, and people
well known members in the community trust.</del>

## Notes on Security and Safety

***TLDR:*** a trusted but malicious actor could hack your system through
this builder. Do not use this builder for secret builds. Be careful
what you use this system for. Do not trust the results. For a more
nuanced understanding, read on.

For someone to use a server as a remote builder, they must be a
`trusted-user` on the remote builder. `man nix.conf` has this to say
about Trusted Users:

> User that have additional rights when connecting to the Nix daemon,
> such as the ability to specify additional binary caches, or to
> import unsigned NARs.
>
> Warning: The users listed here have the ability to compromise the
> security of a multi-user Nix store. For instance, they could install
> Trojan horses subsequently executed by other users. So you should
> consider carefully whether to add users to this list.

Nix's model of remote builders requires users to be able to directly
import files in to the Nix store, and there is no guarantee what they
import hasn't been maliciously modified.

The following is written as me, @grahamc:

I trust everyone who has access, but with limits:

1. I would comfortably run results from this builder on my Raspberry
   Pi that I don't use for secret things.

2. ***DO NOT*** trust this builder for systems that contain private
   data or tools.

3. ***DO NOT*** trust this builder to make binary bootstrap tools,
   because we have to trust those bootstrap tools for a long time to
   not be compromised.

4. ***DO NOT*** trust this builder to make tools used to make binary
   bootstrap tools, because we have to trust those bootstrap tools for
   a long time to not be compromised.

5. ***DO NOT*** trust this builder to build the disk image for this
   builder.

IF YOU ARE: making binary bootstrap tools, please only use tools
built by hydra on a system which have never been exposed to things
built from this server. If you need help with this, I can help.

Note that point 5 ensures that every time the server reboots, it is in
a clean, uncompromised state.

## Notes on Persistence

The deployed system has ***ZERO*** persistence. Do not store anything
on it that you want to keep. It will reboot from time to time and
lose everything on the hard drive.

# Configuring your computer for remote builds

First, put this in your `configuration.nix`:

```nix
{
  programs.ssh.knownHosts."aarch64.nixos.community".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "aarch64.nixos.community";
        maxJobs = 64;
        sshKey = "/root/a-private-key";
        sshUser = "your-user-name";
        system = "aarch64-linux";
        supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
      }
    ];
  };
}
```

**Note:** Make sure the SSH key specified above does *not* have a
password, otherwise `nix-build` will give an error along the lines of:

> unable to open SSH connection to
> 'ssh://your-user-name@aarch64.nixos.community': cannot connect to
> 'your-user-name@aarch64.nixos.community'; trying other available
> machines...

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

Finally, `nix-build . -A hello --argstr system aarch64-linux`.

If this doesn't work, ping @grahamc and I can help debug.

# Faster nixpkgs clone

You may want to clone nixpkgs on the box occasionally. It clones nixpkgs on
boot, allowing faster clones for users — just pass `--reference
/tmp/nixpkgs.git` to your `git clone` command.

---

ps: if you want to build the netbooted image, check out `./DEV_NOTES.md`
