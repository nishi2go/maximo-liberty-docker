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
FROM busybox

LABEL maintainer="nishi2go@gmail.com"

RUN mkdir /images
WORKDIR /images

COPY check.sh /
COPY packages.list /

COPY *.zip *.jar *.gz /images/

RUN chmod +x /check.sh && /check.sh -C /images

# Copy backup files
RUN mkdir /backup
COPY backup/* /backup/

# Unpack the Db2 packages
ARG db_ver=11.1
ARG db_fp=4fp4a
ENV DB2_IMAGE=DB2_AWSE_REST_Svr_${db_ver}_Lnx_86-64.tar.gz
ENV DB2_FP_IMAGE=v${db_ver}.${db_fp}_linuxx64_server_t.tar.gz
RUN mkdir /db2 && tar zxpf /images/${DB2_IMAGE} -C /db2
RUN mkdir /db2fp && tar zxpf /images/${DB2_FP_IMAGE} -C /db2fp

# Unpack the IIM packages
ARG im_image=IED_V1.8.8_Wins_Linux_86.zip
RUN mkdir /Install_Mgr && unzip -q ${im_image} -d /Install_Mgr

ARG mam_image=MAM_7.6.1_LINUX64.tar.gz
ARG mam_fp=2
ARG mam_fp_image=MAMMTFP761${mam_fp}IMRepo.zip

RUN mkdir /Launchpad && tar xpf /images/${mam_image} -C /Launchpad
