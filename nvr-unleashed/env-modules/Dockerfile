FROM dockcross/linux-armv7:20191216-0c64605

WORKDIR /work

RUN git clone --depth=1 --branch=v4.9.44 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

COPY build.sh ./
COPY config.gz ./

CMD /work/build.sh
