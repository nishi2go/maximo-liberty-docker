# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ARG buildver=7.6.1.2
ARG namespace=maximo-liberty
FROM ${namespace}/images:${buildver}

FROM ubuntu:18.04

LABEL maintainer="nishi2go@gmail.com"

ARG backup_dir=/backup
ARG db_alias=MAXDB76
ARG db_port=50005

ENV DB2_PATH /home/ctginst1/sqllib
ENV MAXDB ${db_alias}
ENV MAXDB_SERVICE_PORT ${db_port}
ENV BACKUPDIR ${backup_dir}
ENV DATADIR /home/ctginst1/ctginst1
ENV INITDATADIR /home/ctginst1/init-data

## Install required software
RUN dpkg --add-architecture i386
RUN apt-get update -y && apt-get install -y sudo netcat file libxml2 \
    libx32stdc++6 libpam0g:i386 binutils libaio1 libnuma1 \
    && rm -rf /var/lib/apt/lists/*

# Install IBM DB2
RUN groupadd ctggrp1
RUN groupadd maximo
RUN useradd -g ctggrp1 -m -d /home/ctginst1 ctginst1
RUN useradd -g maximo -m -d /home/maximo maximo
RUN echo "ctginst1    ALL=(root) NOPASSWD: /usr/sbin/chpasswd, $DB2_PATH/instance/db2rfe " >> /etc/sudoers.d/ctginst1

RUN mkdir -p ${BACKUPDIR} && chown ctginst1.ctggrp1 ${BACKUPDIR} && chmod 774 ${BACKUPDIR}
COPY --from=0 --chown=ctginst1:ctggrp1 /backup/* ${BACKUPDIR}/

RUN mkdir -p /work/db2 && chown ctginst1.ctggrp1 /work/db2
COPY --chown=ctginst1:ctggrp1 *.sh /work/db2/
RUN chmod -R 700 /work/db2 && chmod +x /work/db2/*.sh
USER ctginst1
WORKDIR /tmp
RUN mkdir /tmp/db2 && mkdir /tmp/db2fp && chown ctginst1:ctggrp1 /tmp/db2*
COPY --chown=ctginst1:ctggrp1 db2awse.rsp /tmp/
COPY --from=0 --chown=ctginst1:ctggrp1 /db2 /tmp/db2
COPY --from=0 --chown=ctginst1:ctggrp1 /db2fp /tmp/db2fp
RUN ./db2/server_awse_o/db2setup -r db2awse.rsp -f nobackup \
  && ${DB2_PATH}/adm/db2licm -a ./db2/server_awse_o/db2/license/db2awse_o.lic \
  && ${DB2_PATH}/adm/db2licm -l \
  && . ~/sqllib/db2profile && db2stop \
  && cd ./db2fp/server_t \
  && ./installFixPack -n -f update -f nobackup -f db2lib \
  && cd ../.. \
  && rm -rf db2* \ 
  && /work/db2/installdb2.sh \
  && mkdir /home/ctginst1/init-data \
  && cp -rp /home/ctginst1/ctginst1/* /home/ctginst1/init-data/

WORKDIR /work
ENTRYPOINT ["/work/db2/startdb2.sh"]