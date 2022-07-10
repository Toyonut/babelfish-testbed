FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
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

RUN curl -L https://github.com/babelfish-for-postgresql/babelfish-for-postgresql/releases/download/BABEL_2_1_0__PG_14_3/BABEL_2_1_0__PG_14_3.tar.gz --output /opt/BABEL_2_1_0__PG_14_3.tar.gz \
    && tar -xzvf /opt/BABEL_2_1_0__PG_14_3.tar.gz -C /opt/ \
    && mv /opt/BABEL_2_1_0__PG_14_3 /opt/postgres-babelfish

WORKDIR /opt/postgres-babelfish   

ENV JOBS=4 \
    BABELFISH_HOME=/opt/babelfish/2.1 \
    PG_CONFIG=${BABELFISH_HOME}/bin/pg_config \
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
  --prefix=${BABELFISH_HOME}/ \
  --enable-debug \
  --with-ldap \
  --with-libxml \
  --with-pam \
  --with-uuid=ossp \
  --enable-nls \
  --with-libxslt \
  --with-icu \
  && make DESTDIR=${BABELFISH_HOME}/ -j $JOBS 2>error.txt \
  && make install

WORKDIR ${PG_SRC}/contrib 

RUN make -j ${JOBS} \
    && make install

RUN export cmake=$(which cmake) \
    && cp /usr/local/lib/libantlr4-runtime.so.${ANTLR4_VERSION} ${BABELFISH_HOME}/lib
           
WORKDIR ${PG_SRC}/contrib/babelfishpg_tsql/antlr 

RUN cmake -Wno-dev . \
    && make all

WORKDIR ${PG_SRC}/contrib

RUN for ext in babelfishpg_common babelfishpg_money babelfishpg_tds babelfishpg_tsql; \
    do \
        echo "Building ${ext}"; \
        cd $ext; \
        make -j ${JOBS}; \
        make PG_CONFIG=${PG_CONFIG} install; \
        cd ..; \
    done

RUN mkdir -p /var/lib/babelfish/2.1 \
    & adduser postgres --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password \
    && chown -R postgres: /opt/babelfish/ \
    && chown -R postgres: /var/lib/babelfish/ \
    && usermod --home /var/lib/babelfish postgres

ENV BABELFISH_HOME=/opt/babelfish/2.1 \
    BABELFISH_DATA=/var/lib/babelfish/2.1/data

RUN mkdir -p "${BABELFISH_DATA}" && chown -R postgres: "${BABELFISH_DATA}" && chmod 777 "${BABELFISH_DATA}"

COPY entrypoint.sh /usr/local/bin/

RUN chown postgres: /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /opt/babelfish/2.1/bin

USER postgres

STOPSIGNAL SIGINT

EXPOSE 1433
EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["postgres"]
