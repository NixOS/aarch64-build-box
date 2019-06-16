# How to build community builders

Building: Make a `build.cfg` file and run `./build.sh`:

```
pxeUrlPrefix    https://yourdomain.com/pxe-images
pxeUrlSuffix    netboot.ipxe
packetKey       your-packet-api-key
packetDevice    your-packet-device-id
buildHost       user@an-aarch64-capable-build-box
imageName       nixos-packet-aarch64-2018-01-03v1
pxeHost         user@web-accessible-server
pxeDir          /path/to/web/root
```

The build will happen on `buildHost` then copied directly from buildHost
to `pxeHost:pxeDir/imageName` (via netcat and openssl).
If the destination directory already exists, it will be overwritten.

Update the PXE url and restart the server with `./restart.sh`. The PXE
URL will be calculated by `pxeUrlPrefix/imageName/pxeUrlSuffix`.
