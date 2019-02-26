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
FROM ubuntu:16.04

LABEL maintainer="nishi2go@gmail.com"

ARG imagesurl=http://liberty-images

ARG ver=11.1
ARG fp=3fp3
ARG backupdir=/backup
ARG dbalias=MAXDB76

## Install required software
RUN dpkg --add-architecture i386
RUN apt update -y && apt install -y sudo wget unzip bsdtar netcat file \
    libx32stdc++6 libpam0g:i386 binutils libaio1 libnuma1 \
    && rm -rf /var/lib/apt/lists/*

# Install IBM DB2
ENV DB2_IMAGE DB2_AWSE_REST_Svr_${ver}_Lnx_86-64.tar.gz

ENV CTGINST1_PASSWORD changeit
ENV CTGFENC1_PASSWORD changeit
ENV MAXIMO_PASSWORD changeit

RUN groupadd ctggrp1
RUN groupadd ctgfgrp1
RUN groupadd maximo
RUN useradd -g ctggrp1 -m -d /home/ctginst1 ctginst1
RUN useradd -g ctgfgrp1 -m -d /home/ctgfenc1 ctgfenc1
RUN useradd -g maximo -m -d /home/maximo maximo

RUN echo "ctginst1    ALL=(root) NOPASSWD: /usr/sbin/chpasswd" >> /etc/sudoers.d/ctginst1

RUN mkdir ${backupdir}
RUN chown ctginst1.ctggrp1 ${backupdir}

RUN mkdir /work
COPY installdb2.sh /work/
RUN chmod 755 /work/installdb2.sh
RUN chown ctginst1.ctggrp1 /work

ENV DB2_PATH /home/ctginst1/sqllib
ENV MAXDB ${dbalias}
ENV DB2_PORT 50005
ENV BACKUPDIR ${backupdir}

# Install DB2 V11.1
WORKDIR /tmp
USER ctginst1
COPY --chown=ctginst1:ctggrp1 db2awse.rsp /tmp
ENV DB2_FP_IMAGE v${ver}.${fp}_linuxx64_server_t.tar.gz
RUN wget -q ${imagesurl}/$DB2_IMAGE \
  && bsdtar -zxpf $DB2_IMAGE \
  && ./server_awse_o/db2setup -r db2awse.rsp \
  && $DB2_PATH/adm/db2licm -a ./server_awse_o/db2/license/db2awse_o.lic \
  && $DB2_PATH/adm/db2licm -l \
  && rm -rf * \
  && . ~/sqllib/db2profile && db2stop \
# Install DB2 Fixpack
  && wget -q ${imagesurl}/$DB2_FP_IMAGE \
  && bsdtar -zxpf $DB2_FP_IMAGE \
  && cd server_t \
  && ./installFixPack -n -f update -f nobackup -f db2lib  \
  && cd .. \
  && rm -rf * \
# Initial set up
  && /work/installdb2.sh

USER root
COPY *.sh /work/
RUN chmod +x /work/*.sh

WORKDIR /work

ENTRYPOINT ["/work/startdb2.sh"]
