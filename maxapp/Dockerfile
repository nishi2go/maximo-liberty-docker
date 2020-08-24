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
ARG libertyver=20.0.0.3-kernel-java8-ibmjava
FROM maximo-liberty/maximo:${buildver}
FROM maximo-liberty/liberty:${libertyver}

LABEL maintainer="nishi2go@gmail.com"

ARG maximoapp=maximo-ui

COPY --chown=1001:0 --from=0 /opt/IBM/SMP/maximo/deployment/was-liberty-default/deployment/${maximoapp}/${maximoapp}-server/ /config/

RUN installUtility install --acceptLicense defaultServer

ENV MAXIMO_DIR=/maximo
USER root
RUN apt-get update -y && apt-get install -y gettext && rm -rf /var/lib/apt/lists/*
COPY start.sh /opt/ibm/docker/
RUN chmod 555 /opt/ibm/docker/start.sh

RUN wget -q https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin && chmod +x /usr/local/bin/wait-for-it.sh

RUN mkdir -p ${MAXIMO_DIR} && chown -R 1001.0 ${MAXIMO_DIR}
RUN chown -R 1001.0 /config
RUN touch /config/maximo.properties && chown 1001.0 /config/maximo.properties && chmod 640 /config/maximo.properties
USER 1001
COPY --chown=1001:0 maximo.properties.template ${MAXIMO_DIR}

# Default setting for the verbose option
ARG VERBOSE=false

# This script will add the requested XML snippets, grow image to be fit-for-purpose and apply interim fixes
RUN configure.sh

ENV ADMIN_USER_NAME=admin
ENV ADMIN_PASSWORD=changeit
ENV MAXIMO_JMS_SERVICE_HOST=jmsserver
ENV MAXIMO_JMS_SERVICE_PORT=7276
ENV GEN_MAXIMO_PROPERTIES=yes
ENV DB_MAXIMO_PASSWORD=changeit
ENV MAXDB_SERVICE_HOST=maxdb
ENV MAXDB_SERVICE_PORT=50005
ENV MAXDB=maxdb76
#ENV JVM_HEAP_MAX_SIZE=4092m
#ENV JVM_HEAP_MIN_SIZE=512m

CMD ["/opt/ibm/docker/start.sh"]
