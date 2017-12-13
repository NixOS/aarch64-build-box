# Want access? Open a PR adding yourself to users.nix

I'll grant access to well known members of the community, and people
well known members in the community trust.

# Notes

The deployed system has ***ZERO*** persistence. Do not store anything
on it that you want to keep. It will reboot from time to time and
lose everything on the hard drive.

# Configuring your computer for remote builds

1. Put this in your configuration.nix
2. As root run `ssh your-user-name@147.75.79.198 -i /root/a-private-key`
   and make sure it works. If not, ping me and I'll check logs.

```nix
{
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "147.75.79.198";
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
