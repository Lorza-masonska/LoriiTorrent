# syntax=docker/dockerfile:1
ARG DEBIAN_IMAGE=debian:13-slim
FROM ${DEBIAN_IMAGE} AS build

ARG TESTING=ON
ARG BUILD_JOBS=2
ARG QBT_SOURCE=upstream
ARG LIBTORRENT_PATCHES=ON
ARG QT_BASE_PACKAGE_VERSION=6.8.2+dfsg-9+deb13u2
ARG QT_TOOLS_PACKAGE_VERSION=6.8.2-5
ARG BOOST_PACKAGE_VERSION=1.83.0-4.2
ENV GUI=OFF
COPY packaging/install-debian-deps.sh /src/packaging/install-debian-deps.sh
RUN sh /src/packaging/install-debian-deps.sh \
    && rm -rf /var/lib/apt/lists/*
COPY packaging/prepare-libtorrent.py packaging/verify-static-link.py /src/packaging/
COPY packaging/patches/ /src/packaging/patches/
COPY dependencies/libtorrent/ /src/dependencies/libtorrent/
COPY dependencies/libtorrent-source.json /src/dependencies/libtorrent-source.json
RUN python3 /src/packaging/prepare-libtorrent.py --mode "$LIBTORRENT_PATCHES" \
    --jobs "$BUILD_JOBS" --build-root /build/dependencies \
    --result /src/build/libtorrent-prepared.json
COPY ${QBT_SOURCE}/ /src/source/
COPY packaging/build-linux.sh /src/packaging/build-linux.sh
COPY packaging/public-manifest.py /src/packaging/public-manifest.py
COPY README.md NOTICE.md LICENSE PROVENANCE.json /src/
COPY LICENSES/ /src/LICENSES/
RUN QBT_SOURCE=source LIBTORRENT_BUILD_ROOT=/build/dependencies INSTALL_DIR=/stage \
    sh /src/packaging/build-linux.sh

FROM ${DEBIAN_IMAGE} AS runtime
ARG QT_BASE_PACKAGE_VERSION=6.8.2+dfsg-9+deb13u2
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates python3 libssl3t64 zlib1g \
        "libqt6core6t64=${QT_BASE_PACKAGE_VERSION}" \
        "libqt6network6=${QT_BASE_PACKAGE_VERSION}" \
        "libqt6sql6=${QT_BASE_PACKAGE_VERSION}" \
        "libqt6sql6-sqlite=${QT_BASE_PACKAGE_VERSION}" \
        "libqt6xml6=${QT_BASE_PACKAGE_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 loriitorrent \
    && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin loriitorrent \
    && install -d -o 1000 -g 1000 /config/qBittorrent /downloads \
    && ln -s /downloads /config/qBittorrent/downloads
COPY --from=build /stage/usr/bin/qbittorrent-nox /usr/local/bin/qbittorrent-nox
COPY --from=build /stage/usr/share/doc/loriitorrent/ /usr/share/doc/loriitorrent/
COPY --from=build /src/source/COPYING.GPLv2 /src/source/COPYING.GPLv3 /src/source/AUTHORS /usr/share/doc/loriitorrent/licenses/
COPY --from=build /usr/share/doc/libboost1.83-dev/copyright /usr/share/doc/loriitorrent/licenses/Boost-copyright
COPY packaging/third-party/libtorrent-2.0.15-LICENSE /usr/share/doc/loriitorrent/licenses/libtorrent-LICENSE
COPY packaging/third-party/libtorrent-2.0.15/ /usr/share/doc/loriitorrent/licenses/libtorrent/
COPY packaging/patches/ /usr/share/doc/loriitorrent/source-patches/libtorrent/
COPY packaging/qbittorrent-test-locale.patch /usr/share/doc/loriitorrent/source-patches/qbittorrent-test-locale.patch
COPY packaging/qbittorrent-static-link-order.patch /usr/share/doc/loriitorrent/source-patches/qbittorrent-static-link-order.patch
COPY packaging/qbittorrent-webseed-range-diagnostics.patch /usr/share/doc/loriitorrent/source-patches/qbittorrent-webseed-range-diagnostics.patch
RUN dependencies="$(ldd /usr/local/bin/qbittorrent-nox)" \
    && printf '%s\n' "$dependencies" \
    && ! printf '%s\n' "$dependencies" | grep -E 'libtorrent|not found' \
    && qbittorrent-nox --version
ENV HOME=/home/loriitorrent
USER 1000:1000
WORKDIR /downloads
EXPOSE 8080/tcp 6881/tcp 6881/udp
STOPSIGNAL SIGTERM
ENTRYPOINT ["qbittorrent-nox"]
CMD ["--profile=/config", "--confirm-legal-notice", "--webui-port=8080", "--torrenting-port=6881"]
