#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "make update"! PLEASE DO NOT EDIT IT DIRECTLY.
#

# "Experimental"; solely for testing purposes. Anticipate frequent changes!
# This is a multi-stage Dockerfile, requiring a minimum Docker version of 17.05.

ARG DOCKER_CMAKE_BUILD_TYPE=Release
ARG CGAL_GIT_BRANCH=5.6.x-branch
FROM postgres:16.3-bookworm as builder

LABEL maintainer="wangcw - https://github.com/redgreat" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine with database extension PostGIS 3.4.2 + pg_stat_monitor + pg_cron + pg_uuidv7" \
      org.opencontainers.image.source="https://github.com/redgreat/postgres-docker"

WORKDIR /

# apt-get install
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libboost-atomic1.74.0 \
      libboost-chrono1.74.0 \
      libboost-date-time1.74.0 \
      libboost-filesystem1.74.0 \
      libboost-program-options1.74.0 \
      libboost-serialization1.74.0 \
      libboost-system1.74.0 \
      libboost-test1.74.0 \
      libboost-thread1.74.0 \
      libboost-timer1.74.0 \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libprotobuf-c1 \
      libtiff6 \
      libxml2 \
      sqlite3 \
      # build dependency
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      g++ \
      git \
      libboost-all-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libpq-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      make \
      pkg-config \
      protobuf-c-compiler \
      xsltproc \
      # gdal+
      libblosc-dev \
      libcfitsio-dev \
      libfreexl-dev \
      libfyba-dev \
      libhdf5-dev \
      libkml-dev \
      liblz4-dev \
      liblzma-dev \
      libopenjp2-7-dev \
      libqhull-dev \
      libwebp-dev \
      libzstd-dev

ARG DOCKER_CMAKE_BUILD_TYPE
ENV DOCKER_CMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE}

# cgal & sfcgal
# By utilizing the latest commit of the CGAL 5.x.x-branch and implementing a header-only build for SFCGAL,
# one can benefit from the latest CGAL patches while avoiding compatibility issues.
ARG CGAL_GIT_BRANCH
ENV CGAL_GIT_BRANCH=${CGAL_GIT_BRANCH}
# ENV CGAL5X_GIT_HASH dfa981a844c121f4407e1f83092ccc533197b932
# ENV SFCGAL_GIT_HASH a976da3b52692f4d3c30c898eac80673f8507b6d
RUN set -ex \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone --branch ${CGAL_GIT_BRANCH} https://github.com/CGAL/cgal  \
    && cd cgal \
    # && git checkout ${CGAL5X_GIT_HASH} \
    && git log -1 > /_pgis_cgal_last_commit.txt \
    && cd /usr/src \
    && git clone https://gitlab.com/SFCGAL/SFCGAL.git \
    && cd SFCGAL \
    # && git checkout ${SFCGAL_GIT_HASH} \
    && git log -1 > /_pgis_sfcgal_last_commit.txt \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake .. \
       -DCGAL_DIR=/usr/src/cgal \
       -DCMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE} \
       -DSFCGAL_BUILD_BENCH=OFF \
       -DSFCGAL_BUILD_EXAMPLES=OFF \
       -DSFCGAL_BUILD_TESTS=OFF \
       -DSFCGAL_WITH_OSG=OFF \
    && make -j$(nproc) \
    && make install \
    #
    ## testing with -DSFCGAL_BUILD_TESTS=ON
    # && CTEST_OUTPUT_ON_FAILURE=TRUE ctest \
    #
    # clean
    && rm -fr /usr/src/SFCGAL \
    && rm -fr /usr/src/cgal

# proj
# ENV PROJ_GIT_HASH cce46228bde5b7dfa6d3b9048865f43dfbbeda30

RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/OSGeo/PROJ.git \
    && cd PROJ \
    # && git checkout ${PROJ_GIT_HASH} \
    && git log -1 > /_pgis_proj_last_commit.txt \
    # check the autotools exist? https://github.com/OSGeo/PROJ/pull/3027
    && if [ -f "autogen.sh" ] ; then \
        set -eux \
        && echo "autotools version: 'autogen.sh' exists! Older version!"  \
        && ./autogen.sh \
        && ./configure --disable-static \
        && make -j$(nproc) \
        && make install \
        ; \
    else \
        set -eux \
        && echo "cmake version: 'autogen.sh' does not exists! Newer version!" \
        && mkdir build \
        && cd build \
        && cmake .. -DCMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE} -DBUILD_TESTING=OFF \
        && make -j$(nproc) \
        && make install \
        ; \
    fi \
    \
    && rm -fr /usr/src/PROJ

# geos
# ENV GEOS_GIT_HASH 42546119c35e65aad72dea1477eb4a057ead631e
RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/libgeos/geos.git \
    && cd geos \
    # && git checkout ${GEOS_GIT_HASH} \
    && git log -1 > /_pgis_geos_last_commit.txt \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake .. -DCMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE} -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/geos

# gdal
# ENV GDAL_GIT_HASH 0c57764ec2040c4e53c0313844ea5afccdc00279
RUN set -ex \
    && cd /usr/src \
    && git clone https://github.com/OSGeo/gdal.git \
    && cd gdal \
    # && git checkout ${GDAL_GIT_HASH} \
    && git log -1 > /_pgis_gdal_last_commit.txt \
    \
    # gdal project directory structure - has been changed !
    && if [ -d "gdal" ] ; then \
        echo "Directory 'gdal' dir exists -> older version!" ; \
        cd gdal ; \
    else \
        echo "Directory 'gdal' does not exists! Newer version! " ; \
    fi \
    \
    && if [ -f "./autogen.sh" ]; then \
        # Building with autoconf ( old/deprecated )
        set -eux \
        && ./autogen.sh \
        && ./configure --disable-static \
        ; \
    else \
        # Building with cmake
        set -eux \
        && mkdir build \
        && cd build \
        # config based on: https://salsa.debian.org/debian-gis-team/gdal/-/blob/master/debian/rules
        && cmake .. -DCMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE} -DBUILD_TESTING=OFF \
            -DBUILD_DOCS=OFF \
            \
            -DGDAL_HIDE_INTERNAL_SYMBOLS=ON \
            -DRENAME_INTERNAL_TIFF_SYMBOLS=ON \
            -DGDAL_USE_BLOSC=ON \
            -DGDAL_USE_CFITSIO=ON \
            -DGDAL_USE_CURL=ON \
            -DGDAL_USE_DEFLATE=ON \
            -DGDAL_USE_EXPAT=ON \
            -DGDAL_USE_FREEXL=ON \
            -DGDAL_USE_FYBA=ON \
            -DGDAL_USE_GEOS=ON \
            -DGDAL_USE_HDF5=ON \
            -DGDAL_USE_JSONC=ON \
            -DGDAL_USE_LERC_INTERNAL=ON \
            -DGDAL_USE_LIBKML=ON \
            -DGDAL_USE_LIBLZMA=ON \
            -DGDAL_USE_LZ4=ON \
            -DGDAL_USE_OPENJPEG=ON \
            -DGDAL_USE_POSTGRESQL=ON \
            -DGDAL_USE_QHULL=ON \
            -DGDAL_USE_SQLITE3=ON \
            -DGDAL_USE_TIFF=ON \
            -DGDAL_USE_WEBP=ON \
            -DGDAL_USE_ZSTD=ON \
            \
            # OFF and Not working https://github.com/OSGeo/gdal/issues/7100
            # -DRENAME_INTERNAL_GEOTIFF_SYMBOLS=ON \
            -DGDAL_USE_ECW=OFF \
            -DGDAL_USE_GEOTIFF=OFF \
            -DGDAL_USE_HEIF=OFF \
            -DGDAL_USE_SPATIALITE=OFF \
        ; \
    fi \
    \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -fr /usr/src/gdal

# Minimal command line test.
RUN set -ex \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    && pcre-config  --version

# -------------------------------------------
# STAGE  final
# -------------------------------------------
FROM postgres:16-bookworm

ARG DOCKER_CMAKE_BUILD_TYPE
ENV DOCKER_CMAKE_BUILD_TYPE=${DOCKER_CMAKE_BUILD_TYPE}

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libboost-atomic1.74.0 \
      libboost-chrono1.74.0 \
      libboost-date-time1.74.0 \
      libboost-filesystem1.74.0 \
      libboost-program-options1.74.0 \
      libboost-serialization1.74.0 \
      libboost-system1.74.0 \
      libboost-test1.74.0 \
      libboost-thread1.74.0 \
      libboost-timer1.74.0 \
      libcurl3-gnutls \
      libexpat1 \
      libgmp10 \
      libgmpxx4ldbl \
      libjson-c5 \
      libmpfr6 \
      libpcre3 \
      libprotobuf-c1 \
      libtiff6 \
      libxml2 \
      sqlite3 \
      # gdal+
      libblosc1 \
      libcfitsio10 \
      libfreexl1 \
      libfyba0 \
      libhdf5-103-1 \
      libkmlbase1 \
      libkmldom1 \
      libkmlengine1 \
      libopenjp2-7 \
      libqhull-r8.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /_pgis*.* /
COPY --from=builder /usr/local /usr/local
COPY ./mysql/* /tmp/

ARG CGAL_GIT_BRANCH
ENV CGAL_GIT_BRANCH=${CGAL_GIT_BRANCH}
# ENV CGAL5X_GIT_HASH dfa981a844c121f4407e1f83092ccc533197b932
# ENV SFCGAL_GIT_HASH a976da3b52692f4d3c30c898eac80673f8507b6d
# ENV PROJ_GIT_HASH cce46228bde5b7dfa6d3b9048865f43dfbbeda30
# ENV GEOS_GIT_HASH 42546119c35e65aad72dea1477eb4a057ead631e
# ENV GDAL_GIT_HASH 0c57764ec2040c4e53c0313844ea5afccdc00279

# Minimal command line test ( fail fast )
RUN set -ex \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && gdal-config --formats \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    \
    # Testing ogr2ogr PostgreSQL driver.
    && ogr2ogr --formats | grep -q "PostgreSQL/PostGIS" && exit 0 \
            || echo "ogr2ogr missing PostgreSQL driver" && exit 1

# install postgis
# ENV POSTGIS_GIT_HASH 95c525d310b783db4a52d85506ef3cc713238683

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      autotools-dev \
      bison \
      build-essential \
      ca-certificates \
      cmake \
      docbook-xml \
      docbook5-xml \
      g++ \
      git \
      libboost-all-dev \
      libcunit1-dev \
      libcurl4-gnutls-dev \
      libgmp-dev \
      libjson-c-dev \
      libmpfr-dev \
      libpcre3-dev \
      libprotobuf-c-dev \
      libsqlite3-dev \
      libtiff-dev \
      libtool \
      libxml2-dev \
      libxml2-utils \
      make \
      pkg-config \
      postgresql-server-dev-$PG_MAJOR \
      protobuf-c-compiler \
      xsltproc \
    && cd \
    # postgis
    && cd /usr/src/ \
    && git clone https://github.com/postgis/postgis.git \
    && cd postgis \
    # && git checkout ${POSTGIS_GIT_HASH} \
    && git log -1 > /_pgis_last_commit.txt \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
        --enable-lto \
    && make -j$(nproc) \
    && make install \
# refresh proj data - workarounds: https://trac.osgeo.org/postgis/ticket/5316
    && projsync --system-directory --file ch_swisstopo_CHENyx06_ETRS \
    && projsync --system-directory --file us_noaa_eshpgn \
    && projsync --system-directory --file us_noaa_prvi \
    && projsync --system-directory --file us_noaa_wmhpgn \
# regress check
    && mkdir /tempdb \
    && chown -R postgres:postgres /tempdb \
    && su postgres -c 'pg_ctl -D /tempdb init' \
    && su postgres -c 'pg_ctl -D /tempdb -c -l /tmp/logfile -o '-F' start ' \
    && ldconfig \
    && cd regress \
    && make -j$(nproc) check RUNTESTFLAGS=--extension PGUSER=postgres \
    \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch; --needed for postgis_tiger_geocoder "' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS address_standardizer_data_us;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;"' \
    && su postgres -c 'psql    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"' \
    && su postgres -c 'psql -t -c "SELECT version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "SELECT PostGIS_Full_Version();"' >> /_pgis_full_version.txt \
    && su postgres -c 'psql -t -c "\dx"' >> /_pgis_full_version.txt \
    \
    && su postgres -c 'pg_ctl -D /tempdb --mode=immediate stop' \
    && rm -rf /tempdb \
    && rm -rf /tmp/logfile \
    && rm -rf /tmp/pgis_reg

# install FDWS
ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    ORACLE_HOME=/Oracle \
    LD_LIBRARY_PATH=/Oracle \
    ORACLE_VERSION=19.24.0.0.0 \
    ORACLE_DIR_NAME=instantclient_19_24 \
    ORACLE_FDW_VERSION=2_7_0 \
    TDS_FDW_VERSION=2.0.3 \
    PG_STAT_MONITOR_VERSION=2.0.4 \
    PG_UUIDV7_VERSION=1.5.0 \
    MYSQL_FDW_VERSION=2_9_2

RUN set -x \
# set timezone and lang
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG \
    && echo 'LANG="$LANG"' > /etc/default/locale \
# install dev
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget unzip make postgresql-server-dev-"${PG_MAJOR}" gcc libc6-dev libssl-dev libkrb5-dev libaio1 libsybdb5 freetds-dev freetds-common gnupg \
# install oracle_fdw
    && wget -O /tmp/instantclient-basic.zip  https://download.oracle.com/otn_software/linux/instantclient/1924000/instantclient-basiclite-linux.x64-"${ORACLE_VERSION}"dbru.zip \
    && wget -O /tmp/instantclient-sdk.zip  https://download.oracle.com/otn_software/linux/instantclient/1924000/instantclient-sdk-linux.x64-"${ORACLE_VERSION}"dbru.zip \
    && unzip /tmp/instantclient-basic.zip -d /tmp/Oracle \
    && unzip /tmp/instantclient-sdk.zip -d /tmp/Oracle \
    && mv /tmp/Oracle/"${ORACLE_DIR_NAME}" /Oracle \
    && rm -f /Oracle/ojdbc8.jar /Oracle/ucp.jar /Oracle/xstreams.jar \
    && wget -O /tmp/oracle_fdw.zip  https://github.com/laurenz/oracle_fdw/archive/ORACLE_FDW_"${ORACLE_FDW_VERSION}".zip \
    && unzip /tmp/oracle_fdw.zip  -d /tmp \
    && cd /tmp/oracle_fdw-ORACLE_FDW_"${ORACLE_FDW_VERSION}" \
    && make USE_PGXS=1 -j$(nproc) install \
# install tds_fdw
    && wget -O /tmp/tds_fdw.zip https://github.com/tds-fdw/tds_fdw/archive/v"${TDS_FDW_VERSION}".zip \
    && unzip /tmp/tds_fdw.zip  -d /tmp \
    && cd /tmp/tds_fdw-"${TDS_FDW_VERSION}" \
    && make USE_PGXS=1 -j$(nproc) install \
# build pg_cron
    && git clone --depth 1 https://github.com/citusdata/pg_cron.git /tmp/pg_cron\
    && cd /tmp/pg_cron \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
# install mysql_fdw
    && dpkg -i /tmp/mysql-common_8.4.0-1debian12_amd64.deb \
    /tmp/mysql-community-client-plugins_8.4.0-1debian12_amd64.deb \
    /tmp/libmysqlclient24_8.4.0-1debian12_amd64.deb \
    /tmp/libmysqlclient-dev_8.4.0-1debian12_amd64.deb \
    && wget -O /tmp/mysql_fdw.zip https://github.com/EnterpriseDB/mysql_fdw/archive/REL-"${MYSQL_FDW_VERSION}".zip \
    && unzip /tmp/mysql_fdw.zip  -d /tmp \
    && cd /tmp/mysql_fdw-REL-"${MYSQL_FDW_VERSION}" \
    && make USE_PGXS=1 install \
# install pg_stat_monitor
    && wget -O /tmp/pg_stat_monitor.zip https://github.com/percona/pg_stat_monitor/archive/"${PG_STAT_MONITOR_VERSION}".zip \
    && unzip /tmp/pg_stat_monitor.zip  -d /tmp \
    && cd /tmp/pg_stat_monitor-"${PG_STAT_MONITOR_VERSION}" \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
# install uuidv7 \
    && wget -O /tmp/pg_uuidv7.zip https://codeload.github.com/fboulnois/pg_uuidv7/zip/refs/tags/v"${PG_UUIDV7_VERSION}".zip \
    && unzip /tmp/pg_uuidv7.zip  -d /tmp \
    && cd /tmp/pg_uuidv7-"${PG_UUIDV7_VERSION}" \
    && make USE_PGXS=1 -j$(nproc) \
    && make USE_PGXS=1 install \
# install clean
    && apt-get purge -y --autoremove \
    wget \
    unzip \
    gnupg \
    gcc \
    autoconf \
    automake \
    autotools-dev \
    bison \
    build-essential \
    cmake \
    docbook-xml \
    docbook5-xml \
    g++ \
    git \
    libboost-all-dev \
    libcurl4-gnutls-dev \
    libgmp-dev \
    libjson-c-dev \
    libmpfr-dev \
    libpcre3-dev \
    libprotobuf-c-dev \
    libsqlite3-dev \
    libtiff-dev \
    libtool \
    libxml2-dev \
    libxml2-utils \
    libc6-dev  \
    libssl-dev  \
    libkrb5-dev \
    make \
    pkg-config \
    postgresql-server-dev-$PG_MAJOR \
    protobuf-c-compiler \
    xsltproc \
    && apt-get autoremove \
    && apt-get autoclean \
    && cd / \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /usr/src/postgis \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin
COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY docker-entrypoint-after-initdb.sh /docker-entrypoint-initdb.d/0-docker-entrypoint-after-initdb.sh

# last final test
RUN set -ex \
    && ldconfig \
    && cs2cs \
    && ldd $(which gdalinfo) \
    && gdalinfo --version \
    && gdal-config --formats \
    && geos-config --version \
    && ogr2ogr --version \
    && proj \
    && sfcgal-config --version \
    \
    # Is the "ca-certificates" package installed? (for accessing remote raster files)
    #   https://github.com/postgis/docker-postgis/issues/307
    && dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null | grep -c "ok installed" \
    \
    # list last commits.
    && find /_pgis_*_last_commit.txt -type f -print -exec cat {} \;  \
    # list postgresql, postgis version
    && cat _pgis_full_version.txt