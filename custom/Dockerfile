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

# The script is used for customizing Maximo image e.g. to install Industry Solutions, your custom java classes and etc.

ARG buildver=7.6.1.2

FROM maximo-liberty/images:${buildver}

FROM maximo-liberty/maximo-base:${buildver}

## Put the custom installation here or remove comments
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY installis.sh /work/
RUN chmod +x /work/installis.sh

## Sample scripts for Oil & Gas Industry Solution
# ENV IMAGE_NAME Max_Oil_and_Gas_761.zip
# ENV IS_ID com.ibm.tivoli.tpae.IS.OilAndGas
# ENV REPO_FILE OilAndGasInstallerRepository.zip
# ENV WDIR /work/oag
# RUN mkdir ${WDIR}
# COPY --from=0 /images/${IMAGE_NAME} ${WDIR}/
# RUN /work/installis.sh --image=${IMAGE_NAME} \
#  --workdir=${WDIR} --is-id=${IS_ID} --repo-file=${REPO_FILE} --accept-license
# RUN mkdir ${WDIR}
# COPY --from=0 /images/OG7610_ifixes.20200316-0706.zip ${WDIR}/
# RUN unzip -o OG7610_ifixes.20200316-0706.zip -d /opt/IBM/SMP/maximo/ && rm -rf ${WDIR}*
# WORKDIR /work

## Sample scripts for Maximo Scheduler Add on
# ENV IMAGE_NAME MAM_Scheduler_7.6.7.zip
# ENV IS_ID com.ibm.tivoli.tpae.IS.Scheduler
# ENV REPO_FILE SchedulerInstallerRepository.zip
# ENV WDIR /work/sch
# RUN mkdir ${WDIR}
# COPY --from=0 /images/${IMAGE_NAME} ${WDIR}/
# RUN /work/installis.sh --image=${IMAGE_NAME} \
#  --workdir=${WDIR} --is-id=${IS_ID} --repo-file=${REPO_FILE} --accept-license

## Sample scripts for Maximo Linear Add on
# ENV IMAGE_NAME MAX_LNEAR_AST_MGR_7.6.1_MP_ML.zip
# ENV IS_ID com.ibm.tivoli.tpae.IS.Linear
# ENV REPO_FILE LinearInstallerRepository.zip
# ENV WDIR /work/lin
# RUN mkdir ${WDIR}
# COPY --from=0 /images/${IMAGE_NAME} ${WDIR}/
# RUN /work/installis.sh --image=${IMAGE_NAME} \
#  --workdir=${WDIR} --is-id=${IS_ID} --repo-file=${REPO_FILE} --accept-license

## Sample scripts for Maximo for Service Providers Add on
# ENV IMAGE_NAME MAM_SP_V7.6.3_EIMAGE.zip
# ENV FP_IMAGE_NAME 7.6.3.4-TIV-SPRMA-FP0004.zip
# ENV IS_ID com.ibm.tivoli.tpae.IS.ServiceProvider
# ENV REPO_FILE ServiceProviderInstallerRepository.zip
# ENV WDIR /work/msp
# RUN mkdir ${WDIR}
# COPY --from=0 /images/${IMAGE_NAME} ${WDIR}/
# COPY --from=0 /images/${FP_IMAGE_NAME} ${WDIR}/
# RUN /work/installis.sh --image=${IMAGE_NAME} --image-fp=${FP_IMAGE_NAME} \
#  --workdir=${WDIR} --is-id=${IS_ID} --repo-file=${REPO_FILE} --accept-license


RUN /work/buildwars.sh
