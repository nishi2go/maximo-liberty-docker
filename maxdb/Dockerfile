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

FROM ${namespace}/maximo:${buildver}
FROM ${namespace}/db2-intermediate:${buildver}

LABEL maintainer="nishi2go@gmail.com"

ARG backup_dir=/backup
ARG db_alias=MAXDB76
ARG db_port=50005

ENV DB2_PATH /home/ctginst1/sqllib
ENV MAXDB ${db_alias}
ENV MAXDB_SERVICE_PORT ${db_port}
ENV BACKUPDIR ${backup_dir}
ENV SRC_BACKUPDIR /work/backup
ENV DATADIR /home/ctginst1/ctginst1
ENV INITDATADIR /home/ctginst1/init-data

USER root
COPY --chown=ctginst1:ctggrp1 *.sh /work/db2/
RUN chmod -R 700 /work/db2 && chmod +x /work/db2/*.sh
RUN mkdir -p ${BACKUPDIR} && chown ctginst1.ctggrp1 ${BACKUPDIR} && chmod 774 ${BACKUPDIR}
COPY --from=0 --chown=ctginst1:ctggrp1 ${SRC_BACKUPDIR}/* ${BACKUPDIR}/

USER ctginst1
RUN /work/db2/restoreimage.sh \
  && mkdir -p /home/ctginst1/init-data && rm -r /home/ctginst1/init-data/*  \
  && cp -rp /home/ctginst1/ctginst1/* /home/ctginst1/init-data/

WORKDIR /work
ENTRYPOINT ["/work/db2/startdb2.sh"]
