FROM ubuntu:18.04 as build

ARG V8_VERSION=7.7.37
ENV DEBIAN_FRONTEND noninteractive
ENV INSTALL_DIR="/opt/libv8"

RUN set -xe; \
    apt-get update; \
    apt-get install -y build-essential git python libglib2.0-dev patchelf curl wget; \
    cd /tmp; \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git; \
    export PATH=`pwd`/depot_tools:"$PATH"; \
    fetch v8; \
    cd v8; \
    git checkout ${V8_VERSION}; \
    gclient sync; \
    tools/dev/v8gen.py -vv x64.release -- \
	binutils_path=\"/usr/bin\" \
    target_os=\"linux\" \
    target_cpu=\"x64\" \
    v8_target_cpu=\"x64\" \
    v8_use_external_startup_data=false \
    is_official_build=true \
    is_component_build=true \
    is_cfi=false \
    is_clang=false \
    use_custom_libcxx=false \
    use_sysroot=false \
    use_gold=false \
    use_allocator_shim=false \
    treat_warnings_as_errors=false \
    symbol_level=0; \
    \
    ninja -C out.gn/x64.release/; \
    mkdir -p ${INSTALL_DIR}/lib; \
    mkdir -p ${INSTALL_DIR}/include; \
    cp out.gn/x64.release/lib*.so out.gn/x64.release/icudtl.dat ${INSTALL_DIR}/lib/; \
    cp -R include/* ${INSTALL_DIR}/include/; \
    for A in ${INSTALL_DIR}/lib/*.so; do patchelf --set-rpath '$ORIGIN' $A; done;

FROM busybox

ENV INSTALL_DIR="/opt/libv8"

COPY --from=build ${INSTALL_DIR}/include ${INSTALL_DIR}/include
COPY --from=build ${INSTALL_DIR}/lib ${INSTALL_DIR}/lib

VOLUME ${INSTALL_DIR}

CMD /bin/sh

