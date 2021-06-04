FROM ubuntu:18.04
ENV VERSION 1
# install dependencies.
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git make \
    bzip2 automake libbz2-dev libssl-dev doxygen graphviz libgmp3-dev \
    autotools-dev python2.7 python2.7-dev python3 python3-dev python3-pip python3-requests \
    autoconf libtool curl zlib1g-dev sudo ruby libusb-1.0-0-dev \
    libcurl4-gnutls-dev pkg-config patch llvm-7-dev clang-7 vim-common jq bison libreadline-dev flex && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# build cmake
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.16.2/cmake-3.16.2.tar.gz && \
    tar -xzf cmake-3.16.2.tar.gz && \
    cd cmake-3.16.2 && \
    ./bootstrap --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf cmake-3.16.2.tar.gz cmake-3.16.2
# build boost
RUN curl -LO https://boostorg.jfrog.io/artifactory/main/release/1.71.0/source/boost_1_71_0.tar.bz2 && \
    tar -xjf boost_1_71_0.tar.bz2 && \
    cd boost_1_71_0 && \
    ./bootstrap.sh --prefix=/usr/local && \
    ./b2 --with-iostreams --with-date_time --with-filesystem --with-system --with-program_options --with-chrono --with-test -j$(nproc) install && \
    cd / && \
    rm -rf boost_1_71_0.tar.bz2 /boost_1_71_0

# install libpq, postgresql-13
ENV TZ=America/Chicago
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
#    echo "deb http://apt.postgresql.org/pub/repos/apt bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
#    curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
#    apt-get update && apt-get -y install libpq-dev postgresql-13 && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*
# build libqp, no install
RUN curl -L https://github.com/postgres/postgres/archive/refs/tags/REL_13_3.tar.gz | tar zxvf - && \
    cd postgres-REL_13_3  && \
    ./configure && make && make install && \
    cd .. && rm -rf postgres-REL_13_3
ENV PostgreSQL_ROOT=/usr/local/pgsql
ENV PKG_CONFIG_PATH=/usr/local/pgsql/lib/pkgconfig:/usr/local/lib64/pkgconfig
#build libpqxx
RUN curl -L https://github.com/jtv/libpqxx/archive/7.2.1.tar.gz | tar zxvf - && \
    cd  libpqxx-7.2.1  && \
    cmake -DSKIP_BUILD_TEST=ON  -DPostgreSQL_INCLUDE_DIR=/usr/local/pgsql/include  -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/local/pgsql/include  -DPostgreSQL_LIBRARY_DIR=/usr/local/pgsql/lib  -DPostgreSQL_LIBRARY=libpq.a   -DCMAKE_BUILD_TYPE=Release -S . -B build && \
    cmake --build build && cmake --install build && \
    cd .. && rm -rf libpqxx-7.2.1
# install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
# load nvm in non-interactive shells
RUN cp ~/.bashrc ~/.bashrc.bak && \
    cat ~/.bashrc.bak | tail -3 > ~/.bashrc && \
    cat ~/.bashrc.bak | head -n '-3' >> ~/.bashrc && \
    rm ~/.bashrc.bak
# install node 10
RUN bash -c '. ~/.bashrc; nvm install --lts=dubnium' && \
    ln -s "/root/.nvm/versions/node/$(ls -p /root/.nvm/versions/node | sort -Vr | head -1)bin/node" /usr/local/bin/node
RUN curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
RUN sudo apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN useradd postgres &&  mkdir /usr/local/pgsql/data && chown postgres:postgres /usr/local/pgsql/data &&  su - postgres -c "/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data/"
