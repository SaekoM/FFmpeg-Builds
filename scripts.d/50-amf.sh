#!/bin/bash

SCRIPT_REPO="https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git"
SCRIPT_COMMIT="68f2396f1a55a5b12767f5433411bb4093ea65ed"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# AMD AMF hardware encode/decode headers. --disable-hwaccels and --disable-encoders between them
# leave nothing that can call it; the h264_amf / hevc_amf / av1_amf encoders are all disabled.
#
# generate.sh skips the stage and build.sh emits ffbuild_unconfigure instead. Re-enable only
# alongside the variant flag that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerbuild() {
    cd "$FFBUILD_DLDIR/$SELF"

    mkdir -p "$FFBUILD_PREFIX"/include
    mv amf/public/include "$FFBUILD_PREFIX"/include/AMF
}

ffbuild_configure() {
    echo --enable-amf
}

ffbuild_unconfigure() {
    echo --disable-amf
}
