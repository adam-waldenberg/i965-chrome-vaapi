#!/bin/bash
# Build the patched i965 VA-API driver into out/i965_drv_video.so.
# Nothing is installed system wide.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
WORK=$ROOT/build
OUT=$ROOT/out
POOL=https://archive.ubuntu.com/ubuntu/pool/universe/i/intel-vaapi-driver
ORIG=intel-vaapi-driver_2.4.1+dfsg1.orig.tar.xz
DEBIAN=intel-vaapi-driver_2.4.1+dfsg1-1ubuntu0.2.debian.tar.xz
SYSLIB=/usr/lib/x86_64-linux-gnu

mkdir -p "$WORK" "$OUT"
cd "$WORK"

[ -f "$ORIG" ] || curl -fsSL -o "$ORIG" "$POOL/$ORIG"
[ -f "$DEBIAN" ] || curl -fsSL -o "$DEBIAN" "$POOL/$DEBIAN"

# libva and libdrm headers, unpacked locally instead of installed.
if [ ! -d dev ]; then
    mkdir dev dl
    (cd dl && apt-get download libva-dev libdrm-dev)
    for deb in dl/*.deb; do
        dpkg-deb -x "$deb" dev
    done
    for lib in libdrm.so.2 libdrm_intel.so.1 libva.so.2 libva-drm.so.2; do
        ln -sf "$SYSLIB/$lib" "dev/$SYSLIB/$lib"
    done
fi

rm -rf src
mkdir src
tar -xf "$ORIG" -C src --strip-components=1
tar -xf "$DEBIAN" -C src
cd src

for patch in $(cat debian/patches/series); do
    patch -p1 -s < "debian/patches/$patch"
done
for patch in "$ROOT"/patches/*.patch; do
    patch -p1 -s < "$patch"
done

inc=$WORK/dev/usr/include
lib=$WORK/dev$SYSLIB
export PKG_CONFIG_SYSROOT_DIR=$WORK/dev
export PKG_CONFIG_PATH=$lib/pkgconfig:$WORK/dev/usr/share/pkgconfig

autoreconf -fi > /dev/null 2>&1
./configure --disable-x11 --disable-wayland --prefix="$WORK/install" \
    DRM_CFLAGS="-I$inc -I$inc/libdrm" \
    DRM_LIBS="-L$lib -ldrm_intel -ldrm" > "$WORK/configure.log"
make -j"$(nproc)" > "$WORK/make.log"

cp src/.libs/i965_drv_video.so "$OUT/i965_drv_video.so"
strip --strip-unneeded "$OUT/i965_drv_video.so"
echo "Built $OUT/i965_drv_video.so"
