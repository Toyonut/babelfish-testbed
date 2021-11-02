FROM debian:bullseye-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y build-essential flex libxml2-dev libxslt-dev libssl-dev \
    libreadline-dev zlib1g-dev libldap2-dev libpam0g-dev bison \
    uuid uuid-dev lld pkg-config libossp-uuid-dev gnulib \
    libxml2-utils xsltproc icu-devtools libicu67 libicu-dev gawk \
    git python3 python3-dev ca-certificates

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