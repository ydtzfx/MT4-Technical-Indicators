FROM docker.io/mhriemers/metatrader-4@sha256:ed6c3abb2188ac178f183e30bd03cb85c7f2bf8abebfdffa70c070ff2fb1ad74 AS mt4

FROM docker.io/mhriemers/wine@sha256:88fe77b8ad68b4a3a09a9e858aaee6d33aa07533c99da47c7d88fd76e7edac58

ENV WINEPREFIX=/root/.wine
ENV WINEDLLOVERRIDES=mscoree,mshtml=,winebrowser.exe=
ENV WINEDEBUG=warn-all,fixme-all,err-alsa,-ole,-toolbar
ENV WINEARCH=win64

COPY --from=mt4 ["/root/.wine/drive_c/Program Files/MetaTrader 4/metaeditor.exe", "/metaeditor.exe"]
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
