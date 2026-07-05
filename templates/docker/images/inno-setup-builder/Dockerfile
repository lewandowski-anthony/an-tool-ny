FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEPREFIX=/wine
ENV WINEARCH=win64
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV WINEDEBUG="-all,err+all"

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wine \
        wine32:i386 \
        wine64 \
        curl \
        ca-certificates \
        xvfb \
        xauth \
        bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/innosetup && \
    curl -k -SL "https://jrsoftware.org/download.php/is.exe" -o /tmp/is-installer.exe && \
    xvfb-run -a wine /tmp/is-installer.exe /VERYSILENT /SUPPRESSMSGBOXES /DIR="C:\InnoSetup" /PORTABLE=1 && \
    rm -f /tmp/is-installer.exe

WORKDIR /app

ENTRYPOINT ["/bin/bash", "-c", "wine /wine/drive_c/InnoSetup/ISCC.exe \"$@\"; EXIT_CODE=$?; wineserver -k; exit $EXIT_CODE", "--"]