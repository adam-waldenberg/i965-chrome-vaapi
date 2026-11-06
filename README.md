# i965-chrome-vaapi

Patches for the `i965` VA-API driver (intel-vaapi-driver 2.4.1) so that
Chrome's hardware H.264 decode works on Haswell GPUs under X11.

## Why

On Chrome 157 the VA-API decoder starts and is torn down again right away,
and playback falls back to software decoding. Two things in the `i965`
driver cause it:

1. Chrome converts decoded NV12 frames to ARGB with the driver's video
   processing (VPP) entry point. It only accepts `VA_FOURCC_ARGB` as the
   VPP output format. `i965` lists RGBA, RGBX, BGRA and BGRX but not ARGB.
   ARGB has the same memory layout as BGRA (B, G, R, A bytes), so the patch
   adds it to the list.
2. Chrome exports its surfaces as dma-bufs before anything has been
   decoded into them. `i965` allocates surface storage lazily, so
   `vaExportSurfaceHandle` fails with `invalid VASurfaceID`. The patch
   allocates the buffer on export (NV12 for 4:2:0, linear BGRA for RGB32)
   and reports the RGB32 buffer as ARGB.

## Build

    ./build.sh

Downloads the Ubuntu source of the installed driver version, applies the
distribution patches and the patches in `patches/`, builds, and leaves the
stripped driver in `out/i965_drv_video.so`. Nothing is installed system
wide. Headers for libva and libdrm are unpacked into `build/`.

## Use

Point Chrome at the patched driver with two environment variables:

    LIBVA_DRIVERS_PATH=/path/to/out LIBVA_DRIVER_NAME=i965 \
      google-chrome-stable \
      --enable-features=AcceleratedVideoDecodeLinuxGL,VaapiIgnoreDriverChecks

Check `chrome://media-internals`: the video decoder should be
`VaapiVideoDecoder`.

## Tools

- `tools/vpp_formats.py` lists the pixel formats the driver offers for the
  video processing entry point.

## License

The patches modify intel-vaapi-driver, which is MIT licensed.
