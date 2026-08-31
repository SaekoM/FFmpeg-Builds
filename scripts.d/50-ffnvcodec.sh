#!/bin/bash

SCRIPT_REPO="https://github.com/FFmpeg/nv-codec-headers.git"
SCRIPT_COMMIT="855f8263d97bbdcaeabaaaa2997e1ccad7c52dc3"

SCRIPT_REPO2="https://github.com/FFmpeg/nv-codec-headers.git"
SCRIPT_COMMIT2="dc3e4484dc83485734e503991fe5ed3bdf256fba"
SCRIPT_BRANCH2="sdk/11.1"

# DISABLED IN THIS FORK — nothing in this decode-only build can reach it.
#
# NVIDIA CUDA / NVDEC headers. The variant sets --disable-hwaccels, so no hardware decode path
# is compiled and nothing can reach this. It is also what broke the FFmpeg compile: libavutil/
# hwcontext_cuda.c is built whenever --enable-ffnvcodec is passed, and release/6.1 is a MAINTAINED
# branch whose HEAD now calls cu->cuCtxGetCurrent() — a member absent from the 2023 nv-codec-headers
# commit this fork pins. Bumping that pin would fix the compile in order to ship a code path the
# variant cannot use.
#
# generate.sh skips the stage and build.sh emits ffbuild_unconfigure instead. Re-enable only
# alongside the variant flag that would make it reachable.
ffbuild_enabled() {
    return 1
}

ffbuild_dockerdl() {
    default_dl ffnvcodec
    to_df "RUN git-mini-clone \"$SCRIPT_REPO2\" \"$SCRIPT_COMMIT2\" ffnvcodec2"
}

ffbuild_dockerbuild() {
    if [[ $ADDINS_STR == *4.4* || $ADDINS_STR == *5.0* || $ADDINS_STR == *5.1* ]]; then
        cd "$FFBUILD_DLDIR"/ffnvcodec2
    else
        cd "$FFBUILD_DLDIR"/ffnvcodec
    fi

    make PREFIX="$FFBUILD_PREFIX" install
}

ffbuild_configure() {
    echo --enable-ffnvcodec --enable-cuda-llvm
}

ffbuild_unconfigure() {
    echo --disable-ffnvcodec --disable-cuda-llvm
}

ffbuild_cflags() {
    return 0
}

ffbuild_ldflags() {
    return 0
}
