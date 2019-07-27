# keepassxc
#
# mkdir -p "${HOME}/.config/keepassxc" 
# docker run -d \
#		-v /tmp/.X11-unix:/tmp/.X11-unix \
#		-v /etc/machine-id:/etc/machine-id:ro \
#		-v /usr/share/X11/xkb:/usr/share/X11/xkb/:ro \
#		-v $HOME/.config/keepassxc:/home/keepassxc/.config/keepassxc \
#		-e DISPLAY=unix$DISPLAY \
#		westonsteimel/keepassxc
#
ARG KEEPASSXC_VERSION="2.4.3"
FROM alpine:edge as builder

ARG KEEPASSXC_VERSION
ENV KEEPASSXC_VERSION "${KEEPASSXC_VERSION}"

RUN set -x \
    && apk upgrade && apk --no-cache add --virtual .build-dependencies \
	automake \
    argon2-dev \
    bash \
    cmake \
    curl-dev \
    expat \
    g++ \
    gcc \
    git \
    libgcrypt-dev \
    libmicrohttpd-dev \
    make \
    qt5-qtbase-dev \
    qt5-qttools-dev \
    qt5-qtsvg-dev \
    libqrencode-dev \
    libsodium-dev \
    zlib-dev \
    && git clone --depth 1 --branch ${KEEPASSXC_VERSION} https://github.com/keepassxreboot/keepassxc.git /usr/src/keepassxc \
	&& cd /usr/src/keepassxc \
	&& mkdir build \
	&& cd build \
	&& cmake -DCMAKE_BUILD_TYPE=Release \
    -DKEEPASSXC_BUILD_TYPE=Release \
    -DWITH_TESTS=OFF \
    -DWITH_XC_AUTOTYPE=ON \
    -DWITH_XC_HTTP=ON \
    -DWITH_XC_YUBIKEY=OFF \
    -DWITH_XC_KEESHARE=OFF .. \
	&& make \
	&& make install \
	&& apk del .build-dependencies \
	&& rm -rf /usr/src/keepassxc \
	&& echo "keepassxc build complete"

FROM alpine:edge

ARG KEEPASSXC_VERSION

COPY --from=builder /usr/local/bin/keepassxc /usr/local/bin/keepassxc
COPY --from=builder /usr/local/share/keepassxc/ /usr/local/share/keepassxc/

RUN	apk upgrade && apk --no-cache add \
	argon2-libs \
	libcurl \
	libmicrohttpd \
	libgcrypt \
	mesa-dri-intel \
	qt5-qtbase \
	qt5-qtbase-x11 \
	qt5-qttools \
    qt5-qtsvg \
    libqrencode \
    libsodium \
    zlib \
	ttf-dejavu \
    && rm -rf /var/cache/* \
    && addgroup keepassxc \
    && adduser -G keepassxc -s /bin/sh -D keepassxc

USER keepassxc

ENTRYPOINT [ "/usr/local/bin/keepassxc" ]

LABEL org.opencontainers.image.url="https://github.com/westonsteimel/docker-keepassxc" \ 
    org.opencontainers.image.source="https://github.com/westonsteimel/docker-keepassxc" \
    org.opencontainers.image.version="${KEEPASSXC_VERSION}"
