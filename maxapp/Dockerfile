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
ARG buildver=7.6.1.1
ARG libertyver=19.0.0.6-webProfile8
FROM maximo-liberty/maximo:${buildver}
FROM maximo-liberty/liberty:${libertyver}

LABEL maintainer="nishi2go@gmail.com"

ARG maximoapp=maximo-ui

COPY --chown=1001:0 --from=0 /opt/IBM/SMP/maximo/deployment/was-liberty-default/deployment/${maximoapp}/${maximoapp}-server/ /config/

RUN installUtility install --acceptLicense defaultServer

ENV MAXIMO_DIR=/maximo
USER root
COPY start.sh /opt/ibm/docker/
RUN chmod 555 /opt/ibm/docker/start.sh

RUN chown -R 1001.0 /config
RUN touch /config/maximo.properties && chown 1001.0 /config/maximo.properties && chmod 640 /config/maximo.properties
USER 1001

ENV ADMIN_USER_NAME=admin
ENV ADMIN_PASSWORD=changeit
ENV JMS_SERVER_HOST=jmsserver
ENV JMS_SERVER_PORT=9011
#ENV JVM_HEAP_MAX_SIZE=4092m
#ENV JVM_HEAP_MIN_SIZE=512m

CMD ["/opt/ibm/docker/start.sh"]
