FROM debian:bullseye-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y build-essential flex libxml2-dev libxslt-dev libssl-dev \
    libreadline-dev zlib1g-dev libldap2-dev libpam0g-dev bison \
    uuid uuid-dev lld pkg-config libossp-uuid-dev gnulib \
    libxml2-utils xsltproc icu-devtools libicu67 libicu-dev gawk \
    # Extras
    git python3 python3-dev ca-certificates curl software-properties-common

# Packages for extensions
RUN curl https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && apt-get update \
    && apt-get install -y java-1.8.0-amazon-corretto-jdk openssl python-dev libpq-dev pkgconf unzip libutfcpp-dev

WORKDIR /opt

RUN git clone https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish.git \
    && git clone https://github.com/babelfish-for-postgresql/babelfish_extensions.git

WORKDIR /opt/postgresql_modified_for_babelfish

ENV INSTALLATION_PATH="/usr/local/pgsql"

RUN ./configure CFLAGS="${CFLAGS:--Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic}" \
    --prefix=/usr/local/pgsql \
    --enable-thread-safety \
    --enable-cassert \
    --enable-debug \
    --with-ldap \
    --with-python \
    --with-libxml \
    --with-pam \
    --with-uuid=ossp \
    --enable-nls \
    --with-libxslt \
    --with-icu \
    --with-python PYTHON=/usr/bin/python3 \
    --with-extra-version=" Babelfish for PostgreSQL" \
    && \
    mkdir "$INSTALLATION_PATH" \
    # Compiles the Babefish PostgreSQL engine
    && make

# Compiles the PostgreSQL default extensions
WORKDIR /opt/postgresql_modified_for_babelfish/contrib

RUN make

# Installs the Babelfish PostgreSQL engine
WORKDIR /opt/postgresql_modified_for_babelfish

RUN make install

# Installs the PostgreSQL default extensions
WORKDIR /opt/postgresql_modified_for_babelfish/contrib

RUN make install

# Just download a script off the internet and run it to get cmake!
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.20.6/cmake-3.20.6-linux-x86_64.sh --output /opt/cmake-3.20.6-linux-x86_64.sh \
    && chmod +x /opt/cmake-3.20.6-linux-x86_64.sh \
    && /opt/cmake-3.20.6-linux-x86_64.sh --prefix=/usr/local --skip-license

# Just do the same again for antlr4
# Dowloads the compressed Antlr4 Runtime sources on /opt/antlr4-cpp-runtime-4.9.2-source.zip 
RUN curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.2-source.zip \
    --output /opt/antlr4-cpp-runtime-4.9.2-source.zip \
    # Uncompress the source into /opt/antlr4
    && unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.2-source.zip \
    && mkdir /opt/antlr4/build

WORKDIR /opt/antlr4/build

ENV EXTENSIONS_SOURCE_CODE_PATH="/opt/babelfish_extensions"

# Generates the make files for the build
RUN cmake .. -DANTLR_JAR_LOCATION="$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.2-complete.jar" \
    -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True \
    # Compiles and install
    && make \
    && make install \
    && cp /usr/local/lib/libantlr4-runtime.so.4.9.2 "$INSTALLATION_PATH/lib"

ENV PG_CONFIG="$INSTALLATION_PATH/bin/pg_config" \
    PG_SRC="/opt/postgresql_modified_for_babelfish" \
    cmake="/usr/local/bin/cmake"

WORKDIR /opt/babelfish_extensions/contrib/babelfishpg_money

RUN make \
    && make install

# Install babelfishpg_common extension
WORKDIR /opt/babelfish_extensions/contrib/babelfishpg_common

RUN make \
    && make install

# Install babelfishpg_tds extension
WORKDIR /opt/babelfish_extensions/contrib/babelfishpg_tds

RUN make \
    && make install

# Installs the babelfishpg_tsql extension
WORKDIR /opt/babelfish_extensions/contrib/babelfishpg_tsql

RUN make \
    && make install