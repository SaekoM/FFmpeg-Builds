# Godot / EIRTeam.FFmpeg variant: a deliberately tiny decoder set rather than a general FFmpeg.
#
# Everything is switched off first (--disable-decoders --disable-demuxers) and re-enabled by name below,
# so THIS LIST IS EXHAUSTIVE. A codec absent here has no implementation in the output even though its
# name still appears in FFmpeg's codec table — which is exactly why "the DLL mentions av1" was never
# evidence that AV1 would play. Anything the player has to open must be named here.
FF_CONFIGURE="$FF_CONFIGURE --disable-hwaccels --disable-filters --disable-programs --disable-network --disable-encoders --disable-avdevice --disable-muxers --disable-indevs --disable-outdevs --disable-vulkan --disable-decoders --disable-demuxers"
VORBIS="--enable-libvorbis --enable-parser=vorbis --enable-decoder=vorbis --enable-decoder=libvorbis"
VP9="--enable-demuxer=matroska --enable-decoder=vp9 --enable-parser=vp9"
VP8="--enable-decoder=vp8 --enable-parser=vp8"
H264="--enable-decoder=mpeg4,h264,aac,aac_latm,mp3 --enable-demuxer=mov,aac,flv,avi --enable-parser=h264,mpeg4video,mpegaudio,mpegvideo,aac,aac_latm"
OPUS="--enable-libopus --enable-parser=opus --enable-decoder=opus --enable-decoder=libopus"
HEVC="--enable-decoder=hevc --enable-parser=hevc"
# dav1d, deliberately NOT libaom. libaom is the reference decoder and is far too slow for playback; it
# stays linked (scripts.d/50-aom.sh) but with no decoder registered, so VideoDecoder's request for
# "libaom-av1" cannot resolve and falls through to dav1d. That is what lets the GDExtension stay
# unmodified. Registering libaom_av1 here would silently hand playback to the slow path.
#
# --enable-libdav1d is already contributed by scripts.d/50-dav1d.sh; repeated so this line states
# everything AV1 needs in one place.
AV1="--enable-libdav1d --enable-decoder=libdav1d --enable-parser=av1"

FF_CONFIGURE="$FF_CONFIGURE $VORBIS $VP9 $VP8 $H264 $OPUS $HEVC $AV1"

# Hold FFmpeg at 6.1. defaults-lgpl.sh sets GIT_BRANCH=master, which now builds avcodec-62 — but the
# EIRTeam.FFmpeg GDExtension links avcodec-60, so an unpinned build produces libraries it cannot load at
# all. Staying on 6.1 keeps every SONAME (avcodec-60 / avformat-60 / avutil-58 / swscale-7 /
# swresample-4 / avfilter-9) identical to the DLLs already shipping, which makes the output a drop-in
# swap that needs no GDExtension rebuild.
#
# This file is sourced AFTER defaults-lgpl-shared.sh (see win64-lgpl-godot.sh), so the override lands.
GIT_BRANCH="release/6.1"
