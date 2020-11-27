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
ARG base_maximo_build=ubuntu:18:04
ARG namespace=maximo-liberty

FROM ${namespace}/images:${buildver}

FROM ${base_maximo_build}

LABEL maintainer="nishi2go@gmail.com"

ARG update_im=no
ARG fp=2
ARG db_alias=MAXDB76
ARG enable_jms=yes
ARG install_fp=yes
ARG skip_build=no
ARG deploy_db_on_build=yes
ARG backup_dir=/backup
ARG db_alias=MAXDB76
ARG mxintadm_password
ARG maxadmin_password
ARG db_maximo_password
ARG maxreg_password
ARG db_port=50005
ARG base_lang=en
ARG add_langs
ARG admin_email_address=root@localhost
ARG smtp_server_host_name=localhost
ARG skin=iot18
ARG enable_demo_data=no

ENV DB2_PATH /home/ctginst1/sqllib
ENV MAXDB ${db_alias}
ENV MAXDB_SERVICE_PORT ${db_port}
ENV BACKUPDIR /work/backup

ENV TEMP /tmp
WORKDIR /tmp

USER root
# Install IBM Installation Manager 1.8.8
RUN mkdir /Install_Mgr 
COPY --from=0 /Install_Mgr /Install_Mgr/
RUN /Install_Mgr/EnterpriseDVD/Linux_x86_64/EnterpriseCD-Linux-x86_64/InstallationManager/installc -log /tmp/IM_Install_Unix.xml -acceptLicense \
 && rm -rf /Install_Mgr

## Update Installation Manager
RUN if [ "${update_im}" = "yes" ]; then /opt/IBM/InstallationManager/eclipse/tools/imcl install com.ibm.cic.agent; fi

ENV TEMP /tmp
WORKDIR /tmp

# Install required packages
RUN apt-get update && apt-get install -y netcat wget gettext inetutils-ping \
 dos2unix apache2 xmlstarlet && rm -rf /var/lib/apt/lists/*

## Install Maximo middleware and installer
RUN mkdir /Launchpad
WORKDIR /Launchpad

## Install Maximo V7.6.1
ENV BYPASS_PRS=True
# Remove z from tar command because file is not gzipped despite having gz extension
COPY --from=0 /Launchpad /Launchpad/
RUN /opt/IBM/InstallationManager/eclipse/tools/imcl \
 -input /Launchpad/SilentResponseFiles/Unix/ResponseFile_MAM_Install_Unix.xml \
 -acceptLicense -log /tmp/MAM_Install_Unix.xml \
 && rm -rf /Launchpad

# Install Maximo V7.6.1 feature pack
RUN mkdir -p /work
WORKDIR /work
ENV MAM_FP_IMAGE MAMMTFP761${fp}IMRepo.zip
COPY --from=0 /images/${MAM_FP_IMAGE} /work/
RUN if [ "${install_fp}" = "yes" ]; then /opt/IBM/InstallationManager/eclipse/tools/imcl install \
 com.ibm.tivoli.tpae.base.tpae.main -repositories /work/${MAM_FP_IMAGE} \
 -installationDirectory /opt/IBM/SMP -log /tmp/TPAE_FP_Install_Unix.xml -acceptLicense \
 && /opt/IBM/InstallationManager/eclipse/tools/imcl install \
 com.ibm.tivoli.tpae.base.mam.main -repositories /work/${MAM_FP_IMAGE} \
 -installationDirectory /opt/IBM/SMP -log /tmp/MAM_FP_Install_Unix.xml -acceptLicense \
 && rm /work/${MAM_FP_IMAGE}; fi

RUN dos2unix /opt/IBM/SMP/maximo/deployment/was-liberty-default/*.sh

COPY *.sh /work/
RUN chmod +x /work/*.sh
RUN /work/buildwars.sh

RUN mkdir /opt/IBM/SMP/maximo/tools/maximo/en/liberty
COPY liberty.dbc /opt/IBM/SMP/maximo/tools/maximo/en/liberty/

RUN wget -q https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin && chmod +x /usr/local/bin/wait-for-it.sh

COPY maximo-config.properties.template /opt/

ENV MAXIMO_DIR /maximo
ENV MAXDB ${db_alias}
ENV DB_VENDOR DB2
ENV DB_TABLE_SPACE MAXDATA
ENV DB_TEMP_SPACE MAXTEMP
ENV DB_INDEX_SPACE MAXINDEX

RUN /work/startinstallonbuild.sh

RUN if [ "${deploy_db_on_build}" = "no" ]; then mkdir -p ${BACKUPDIR} && touch ${BACKUPDIR}/placeholder ; fi

ENTRYPOINT ["/work/startinstall.sh"]
