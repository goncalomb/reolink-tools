FROM dockcross/linux-armv7l-musl:20211020-e607d12

WORKDIR /work

COPY lib ./lib
COPY lib-patches ./lib-patches
COPY build.sh ./
COPY patches.sh ./

CMD /work/build.sh
