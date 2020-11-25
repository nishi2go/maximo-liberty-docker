#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Installation script for Industry solutions and addons

INST_FP=0
IMCL="/opt/IBM/InstallationManager/eclipse/tools/imcl"
MAXIMO_DIR="/opt/IBM/SMP"

while [[ $# -gt 0 ]]; do
  key="${1}"
    case "${key}" in
      "--image="* )
        IMAGE_NAME="${key#*=}"
        ;;
      "--image-fp="* )
        FP_IMAGE_NAME="${key#*=}"
        INST_FP=1
        ;;
      "--workdir="* )
        WDIR="${key#*=}"
        ;;
      "--is-id="* )
        IS_ID="${key#*=}"
        ;;
      "--repo-file="* )
        REPO_FILE="${key#*=}"
        ;;
      --accept-license )
        ACCEPT_LICENSE="-acceptLicense"
        ;;
    esac
    shift
done

unzip -q ${WDIR}/${IMAGE_NAME} -d ${WDIR} || exit 1
${IMCL} install ${IS_ID} -repositories ${WDIR}/${REPO_FILE} -installationDirectory ${MAXIMO_DIR} ${ACCEPT_LICENSE} || exit 2

if [[ ${INST_FP} -eq 1 ]]; then
  ${IMCL} install ${IS_ID} -repositories ${WDIR}/${FP_IMAGE_NAME} -installationDirectory ${MAXIMO_DIR} ${ACCEPT_LICENSE} || exit 3
fi

rm -rf ${WDIR}/*