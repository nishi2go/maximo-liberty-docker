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
ARG namespace=maximo-liberty

FROM ${namespace}/images:${buildver}
FROM websphere-liberty:${libertyver}

LABEL maintainer="nishi2go@gmail.com"

# Install required packages
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends wget \
 && rm -rf /var/lib/apt/lists/*
RUN wget -q https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && mv wait-for-it.sh /usr/local/bin && chmod +x /usr/local/bin/wait-for-it.sh
USER 1001

WORKDIR /tmp
COPY --chown=1001:0 --from=0 /images/wlp-nd-license.jar /tmp/
RUN java -jar /tmp/wlp-nd-license.jar --acceptLicense /opt/ibm \
 && rm /tmp/wlp-nd-license.jar

ENV KEYSTORE_REQUIRED false
ENV SEC_TLS_TRUSTDEFAULTCERTS true