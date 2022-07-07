FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt install -y --no-install-recommends \
  build-essential flex libxml2-dev libxml2-utils \
  libxslt-dev libssl-dev libreadline-dev zlib1g-dev \
  libldap2-dev libpam0g-dev gettext uuid uuid-dev \
  cmake lld apt-utils libossp-uuid-dev gnulib bison \
  xsltproc icu-devtools libicu66 \
  libicu-dev gawk \
  curl openjdk-8-jre openssl \
  g++ libssl-dev python-dev libpq-dev \
  pkg-config libutfcpp-dev \
  gnupg unixodbc-dev net-tools unzip ca-certificates wget

RUN curl -L https://github.com/babelfish-for-postgresql/babelfish-for-postgresql/releases/download/BABEL_1_2_0__PG_13_6/BABEL_1_2_0__PG_13_6.tar.gz --output /opt/BABEL_1_2_0__PG_13_6.tar.gz \
    && tar -xzvf /opt/BABEL_1_2_0__PG_13_6.tar.gz -C /opt/ \
    && mv /opt/BABEL_1_2_0__PG_13_6 /opt/postgres-babelfish

WORKDIR /opt/postgres-babelfish   

ENV JOBS=4 \
    BABELFISH_HOME=/opt/babelfish \
    PG_CONFIG=${BABELFISH_HOME}/1.2/bin/pg_config \
    PG_SRC=/opt/postgres-babelfish \
    ANTLR4_VERSION=4.9.3 \
    ANTLR4_JAVA_BIN=/usr/bin/java \
    ANTLR4_RUNTIME_LIBRARIES=/usr/include/antlr4-runtime \
    ANTLR_EXECUTABLE=/usr/local/lib/antlr-${ANTLR4_VERSION}-complete.jar \
    ANTLR_RUNTIME=/opt/antlr4

RUN cp ${PG_SRC}/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-${ANTLR4_VERSION}-complete.jar /usr/local/lib

WORKDIR /opt

RUN curl -L http://www.antlr.org/download/antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip -o /opt/antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip \
    && unzip /opt/antlr4-cpp-runtime-${ANTLR4_VERSION}-source.zip -d ${ANTLR_RUNTIME}

WORKDIR ${ANTLR_RUNTIME}

RUN mkdir build && cd build \
    && cmake .. -D ANTLR_JAR_LOCATION=/usr/local/lib/antlr-${ANTLR4_VERSION}-complete.jar -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True \
    && make -j $JOBS \
    && make install

WORKDIR ${PG_SRC}

RUN ./configure CFLAGS="-ggdb" \
  --prefix=${BABELFISH_HOME}/1.2/ \
  --enable-debug \
  --with-ldap \
  --with-libxml \
  --with-pam \
  --with-uuid=ossp \
  --enable-nls \
  --with-libxslt \
  --with-icu \
    && make DESTDIR=${BABELFISH_HOME}/1.2/ -j $JOBS 2>error.txt \
    && make install

RUN export cmake=$(which cmake) \
    && cp /usr/local/lib/libantlr4-runtime.so.${ANTLR4_VERSION} ${BABELFISH_HOME}/1.2/lib

WORKDIR ${PG_SRC}/contrib/babelfishpg_tsql/antlr

RUN cmake -Wno-dev .

WORKDIR $PG_SRC/contrib/ 

RUN make -j $JOBS && make install 

RUN mkdir -p /var/lib/babelfish/1.2 \
    && adduser postgres --home /var/lib/babelfish --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password \
    && chown -R postgres: ${BABELFISH_HOME}/ \
    && chown -R postgres: /var/lib/babelfish/

WORKDIR ${BABELFISH_HOME}/bin

USER postgres


