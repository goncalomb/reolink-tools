FROM dockcross/linux-armv7l-musl:20211020-e607d12

WORKDIR /work

RUN apt -y update
RUN apt -y install golang

COPY lib ./lib
COPY src ./src
COPY lib-patches ./lib-patches
COPY build.sh ./
COPY patches.sh ./

CMD /work/build.sh
