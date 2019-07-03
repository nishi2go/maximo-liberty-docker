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
FROM maximo-liberty/ibmim

LABEL maintainer="nishi2go@gmail.com"

ARG fp=1
ARG imagesurl=http://liberty-images
ARG installfp=yes
ARG enablejms=yes
ARG dbalias=MAXDB76

ENV TEMP /tmp
WORKDIR /tmp

# Install required packages
RUN apt-get update && apt-get install -y netcat wget inetutils-ping \
 dos2unix apache2 xmlstarlet && rm -rf /var/lib/apt/lists/*

## Install Maximo middleware and installer
RUN mkdir /Launchpad
WORKDIR /Launchpad

## Install Maximo V7.6.1
ENV BYPASS_PRS=True
ENV MAM_IMAGE MAM_7.6.1_LINUX64.tar.gz
ENV MAM_FP_IMAGE MAMMTFP761${fp}IMRepo.zip
# Remove z from tar command because file is not gzipped despite having gz extension
RUN wget -q ${imagesurl}/$MAM_IMAGE && tar xpf $MAM_IMAGE \
 && /opt/IBM/InstallationManager/eclipse/tools/imcl \
 -input /Launchpad/SilentResponseFiles/Unix/ResponseFile_MAM_Install_Unix.xml \
 -acceptLicense -log /tmp/MAM_Install_Unix.xml \
 && rm $MAM_IMAGE && rm -rf /Launchpad

# Install Maximo V7.6.1 feature pack
RUN mkdir /work
WORKDIR /work
ENV MAM_FP_IMAGE MAMMTFP761${fp}IMRepo.zip
RUN if [ "${installfp}" = "yes" ]; then wget -q ${imagesurl}/$MAM_FP_IMAGE && sleep 10 \
 && /opt/IBM/InstallationManager/eclipse/tools/imcl install \
 com.ibm.tivoli.tpae.base.tpae.main -repositories /work/$MAM_FP_IMAGE \
 -installationDirectory /opt/IBM/SMP -log /tmp/TPAE_FP_Install_Unix.xml -acceptLicense \
 && /opt/IBM/InstallationManager/eclipse/tools/imcl install \
 com.ibm.tivoli.tpae.base.mam.main -repositories /work/$MAM_FP_IMAGE \
 -installationDirectory /opt/IBM/SMP -log /tmp/MAM_FP_Install_Unix.xml -acceptLicense \
 && rm /work/$MAM_FP_IMAGE; fi

RUN dos2unix /opt/IBM/SMP/maximo/deployment/was-liberty-default/*.sh

COPY *.sh /work/
RUN chmod +x /work/*.sh && /work/buildwars.sh && rm /work/buildwars.sh

RUN mkdir /opt/IBM/SMP/maximo/tools/maximo/en/liberty
COPY liberty.dbc /opt/IBM/SMP/maximo/tools/maximo/en/liberty/

RUN wget -q https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin && chmod +x /usr/local/bin/wait-for-it.sh

ENV MAXIMO_DIR /maximo
ENV MAXDB ${dbalias}

ENTRYPOINT ["/work/startinstall.sh"]
