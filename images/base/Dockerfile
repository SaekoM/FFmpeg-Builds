FROM ubuntu:23.04

ENV FFBUILD_DLDIR="/opt/ffdl"

ENV DEBIAN_FRONTEND noninteractive

# 23.04 is past end of life, so its packages have moved off the default archive hosts and the apt-get
# update below 404s on a stock image. Point apt at old-releases before anything tries to use it.
#
# Pinned to this release rather than bumped to a supported one on purpose: a bump changes the whole
# toolchain — and, for the Linux target, the glibc floor the shipped .so ends up demanding — which would
# land a toolchain change and a codec change in the same build. Change one thing at a time.
#
# Handles both apt layouts (23.04 uses sources.list; deb822 .sources arrived in 24.04) so this survives
# a later base bump, and never fails the build if neither is present.
RUN for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do \
        [ -f "$f" ] && sed -i \
            -e 's|archive.ubuntu.com|old-releases.ubuntu.com|g' \
            -e 's|security.ubuntu.com|old-releases.ubuntu.com|g' \
            -e 's|ports.ubuntu.com|old-releases.ubuntu.com|g' "$f"; \
    done; true

RUN \
    mkdir -p "$FFBUILD_DLDIR" && \
    apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install build-essential yasm nasm \
        xxd pkgconf curl wget unzip git subversion mercurial \
        autoconf automake libtool libtool-bin autopoint gettext cmake clang meson ninja-build \
        texinfo texi2html help2man flex bison groff \
        gperf itstool ragel libc6-dev libssl-dev \
        gtk-doc-tools gobject-introspection gawk \
        ocaml ocamlbuild libnum-ocaml-dev indent p7zip-full \
        python3-distutils python3-jinja2 python3-jsonschema python3-apt python-is-python3 && \
    apt-get -y clean && \
    git config --global user.email "builder@localhost" && \
    git config --global user.name "Builder" && \
    git config --global advice.detachedHead false

ENV CARGO_HOME="/opt/cargo" RUSTUP_HOME="/opt/rustup" PATH="/opt/cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path && \
    cargo install cargo-c && rm -rf "${CARGO_HOME}"/registry "${CARGO_HOME}"/git

RUN --mount=src=.,dst=/input \
    for s in /input/*.sh; do cp $s /usr/bin/$(echo $s | sed -e 's|.*/||' -e 's/\.sh$//'); done
