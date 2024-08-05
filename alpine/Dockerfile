#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "make update"! PLEASE DO NOT EDIT IT DIRECTLY.
#
ARG BASE_IMAGE=postgres:16-alpine3.20
FROM ${BASE_IMAGE}

LABEL maintainer="wangcw - https://github.com/redgreat" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine with database extension PostGIS 3.4.2 + pg_stat_monitor + pg_cron + pg_uuidv7" \
      org.opencontainers.image.source="https://github.com/redgreat/postgres-docker"

ENV POSTGIS_VERSION=3.4.2 \
    POSTGIS_SHA256=17aa8760a5c4fcb9a1fdc750c1c9aca0198a35dd1e320628064c43f178eefed2 \
    TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    ORACLE_HOME=/Oracle \
    LD_LIBRARY_PATH=/Oracle \
    ORACLE_VERSION=19.23.0.0.0 \
    ORACLE_DIR_NAME=instantclient_19_23 \
    ORACLE_FDW_VERSION=2_7_0 \
    PG_CRON_VERSION=1.2.0 \
    MYSQL_MAJOR=8.0 \
    MYSQL_VERSION=8.4.2 \
    MYSQL_FDW_VERSION=2_9_2

RUN set -eux \
    # set timezone and lang
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
        wget  \
        unzip \
        glibc \
        tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG \
    && echo 'LANG="$LANG"' > /etc/default/locale \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
    && wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-bin-2.35-r1.apk \
    && wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-i18n-2.35-r1.apk \
    && apk add glibc-2.35-r1.apk glibc-bin-2.35-r1.apk glibc-i18n-2.35-r1.apk \
    && rm -rf /usr/lib/jvm glibc-2.35-r1.apk glibc-bin-2.35-r1.apk  glibc-i18n-2.35-r1.apk \
    && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/${POSTGIS_VERSION}.tar.gz" \
    && echo "${POSTGIS_SHA256} *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        \
        gdal-dev \
        geos-dev \
        proj-dev \
        proj-util \
        sfcgal-dev \
        \
        # The upstream variable, '$DOCKER_PG_LLVM_DEPS' contains
        #  the correct versions of 'llvm-dev' and 'clang' for the current version of PostgreSQL.
        # This improvement has been discussed in https://github.com/docker-library/postgres/pull/1077
        $DOCKER_PG_LLVM_DEPS \
        \
        autoconf \
        automake \
        cunit-dev \
        file \
        g++ \
        make \
        gcc \
        gettext-dev \
        git \
        json-c-dev \
        libtool \
        libxml2-dev \
        pcre2-dev \
        perl \
        protobuf-c-dev \
        gnupg \
    \
# build PostGIS - with Link Time Optimization (LTO) enabled
    && cd /usr/src/postgis \
    && gettextize \
    && ./autogen.sh \
    && ./configure \
        --enable-lto \
    && make -j$(nproc) \
    && make install \
    \
# build pg_stat_monitor
    && git clone --depth 1 https://github.com/percona/pg_stat_monitor \
    && cd pg_stat_monitor \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
    && cd .. \
    \
# build pg_cron
    && git clone --depth 1 https://github.com/citusdata/pg_cron.git \
    && cd pg_cron \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
    && cd .. \
    \
# build uuidv7
    && git clone --depth 1 https://github.com/fboulnois/pg_uuidv7 \
    && cd pg_uuidv7 \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
    && cd .. \
    \
# install oracle_fdw
    && wget -O /tmp/instantclient-basic.zip https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basiclite-linux.x64-"${ORACLE_VERSION}"dbru.zip \
    && wget -O /tmp/instantclient-sdk.zip https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-sdk-linux.x64-"${ORACLE_VERSION}"dbru.zip \
    && unzip /tmp/instantclient-basic.zip -o -d /tmp/Oracle \
    && unzip /tmp/instantclient-sdk.zip -o -d /tmp/Oracle \
    && mv /tmp/Oracle/"${ORACLE_DIR_NAME}" /Oracle \
    && rm -f /Oracle/ojdbc8.jar /Oracle/ucp.jar /Oracle/xstreams.jar \
    && wget -O /tmp/oracle_fdw.zip  https://github.com/laurenz/oracle_fdw/archive/ORACLE_FDW_"${ORACLE_FDW_VERSION}".zip \
    && unzip /tmp/oracle_fdw.zip  -d /tmp \
    && cd /tmp/oracle_fdw-ORACLE_FDW_"${ORACLE_FDW_VERSION}" \
    && make USE_PGXS=1 install \
# install mysql_fdw
    && wget  -O /tmp/mysql-common.deb https://dev.mysql.com/get/Downloads/MySQL-"${MYSQL_MAJOR}"/mysql-common_"${MYSQL_VERSION}"-1debian10_amd64.deb \
    && wget  -O /tmp/libmysqlclient.deb https://dev.mysql.com/get/Downloads/MySQL-"${MYSQL_MAJOR}"/libmysqlclient21_"${MYSQL_VERSION}"-1debian10_amd64.deb \
    && wget  -O /tmp/libmysqlclient-dev.deb https://dev.mysql.com/get/Downloads/MySQL-"${MYSQL_MAJOR}"/libmysqlclient-dev_"${MYSQL_VERSION}"-1debian10_amd64.deb \
    && dpkg -i /tmp/mysql-common.deb /tmp/libmysqlclient.deb /tmp/libmysqlclient-dev.deb \
    && wget -O /tmp/mysql_fdw.zip https://github.com/EnterpriseDB/mysql_fdw/archive/REL-"${MYSQL_FDW_VERSION}".zip \
    && unzip /tmp/mysql_fdw.zip  -d /tmp \
    && cd /tmp/mysql_fdw-REL-"${MYSQL_FDW_VERSION}" \
    && make USE_PGXS=1 install \
# This section is for refreshing the proj data for the regression tests.
# It serves as a workaround for an issue documented at https://trac.osgeo.org/postgis/ticket/5316
# This increases the Docker image size by about 1 MB.
    && projsync --system-directory --file ch_swisstopo_CHENyx06_ETRS \
    && projsync --system-directory --file us_noaa_eshpgn \
    && projsync --system-directory --file us_noaa_prvi \
    && projsync --system-directory --file us_noaa_wmhpgn \
# This section performs a regression check.
    && mkdir /tempdb \
    && chown -R postgres:postgres /tempdb \
    && su postgres -c 'pg_ctl -D /tempdb init' \
    && su postgres -c 'pg_ctl -D /tempdb -c -l /tmp/logfile -o '-F' start ' \
    && cd regress \
    && make -j$(nproc) check RUNTESTFLAGS=--extension   PGUSER=postgres \
    \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS postgis;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch; --needed for postgis_tiger_geocoder "' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS address_standardizer;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS address_standardizer_data_us;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;"' \
    && su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"' \
    && su postgres -c 'psql -t -c "SELECT version();"'              >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "SELECT PostGIS_Full_Version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "\dx"' >> /_pgis_full_version.txt \
    \
    && su postgres -c 'pg_ctl -D /tempdb --mode=immediate stop' \
    && rm -rf /tempdb \
    && rm -rf /tmp/logfile \
    && rm -rf /tmp/pgis_reg \
# add .postgis-rundeps
    && apk add --no-cache --virtual .postgis-rundeps \
        \
        gdal \
        geos \
        proj \
        sfcgal \
        \
        json-c \
        libstdc++ \
        pcre2 \
        protobuf-c \
        \
        # ca-certificates: for accessing remote raster files
        #   fix https://github.com/postgis/docker-postgis/issues/307
        ca-certificates \
# clean
    && cd / \
    && rm -rf /usr/src/postgis \
    && rm -rf pg_stat_monitor \
    && rm -rf pg_cron \
    && rm -rf pg_uuidv7 \
    && apk del .fetch-deps .build-deps \
    && apt-get purge -y --auto-remove wget unzip make gnupg gcc \
    && apt-get autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
# At the end of the build, we print the collected information
# from the '/_pgis_full_version.txt' file. This is for experimental and internal purposes.
    && cat /_pgis_full_version.txt

COPY ../initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY ../docker-entrypoint-after-initdb.sh /docker-entrypoint-initdb.d/0-docker-entrypoint-after-initdb.sh
COPY ../update-postgis.sh /usr/local/bin
