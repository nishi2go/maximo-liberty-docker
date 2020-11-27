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

source .env

MAXIMO_VER="${ENV_MAXIMO_VER:-7.6.1.2}"
FP_VER="${ENV_FP_VER:-2}"
WAS_VER="${ENV_WAS_VER:-20.0.0.3-kernel-java8-ibmjava}"
PROXY_VER="${PROXY_VER:-1.8}"
DEFAULT_BUILD_ARGS=" --build-arg buildver=${MAXIMO_VER} "
DEFAULT_BUILD_ARGS_FILE="build.args"

DOCKER="${DOCKER_CMD:-docker}"

NAME_SPACE="maximo-liberty"
REMOVE=0
SKIP_DB=0
DEPLOY_ON_BUILD=-1
QUIET=-q
PRUNE=0
ADD_LATEST_TAG=1
REMOTE_REGISTRY=""
INTERMEDIATE_BUILD_IMAGE_ID="ubuntu:18.04"

# Usage: remove "tag name" "version" "product name"
function remove {
  image_id=`${DOCKER} images -q --no-trunc ${NAME_SPACE}/${1}:${2}`
  if [[ ! -z "${image_id}" ]]; then
    echo "${3} image exists. Remove it."
    container_ids=`${DOCKER} ps -aq --no-trunc -f ancestor=${image_id}`
    if [[ ! -z "${container_ids}" ]]; then
      ${DOCKER} container rm -f ${container_ids}
    fi
    ${DOCKER} image rm -f "${image_id}"
  fi
  if [[ -n "${REMOTE_REGISTRY}" ]]; then
    ${DOCKER} image rm ${REMOTE_REGISTRY}/${NAME_SPACE}/${1}:${2}
  fi
}

# Usage: build "tag name" "version" "target directory name" "product name"
function build {
  echo "Start to build ${4} image"
  if [[ ${ADD_LATEST_TAG} -eq 1 ]]; then
    LT="-t ${NAME_SPACE}/${1}:latest"
  fi
  ${DOCKER} build ${QUIET}  ${5}  ${EXTRA_BUILD_ARGS}  ${DEFAULT_BUILD_ARGS}  --rm -t ${NAME_SPACE}/${1}:${2} ${LT} ${3} || exit 1

  exists=`${DOCKER} images -q --no-trunc ${NAME_SPACE}/${1}:${2}`
  if [[ -z "${exists}" ]]; then
    echo "Failed to create ${4} image."
    exit 2
  fi
  echo "Completed ${4} image creation."
}

# Usage: push "tag name" "version" "product name"
function push {
  if [[ -n "${REMOTE_REGISTRY}" ]]; then
    echo "Start to push ${3} image"
    ${DOCKER} tag ${QUIET} ${NAME_SPACE}/${1}:${2} ${REMOTE_REGISTRY}/${NAME_SPACE}/${1}:${2} || exit 1
    ${DOCKER} push ${QUIET} ${REMOTE_REGISTRY}/${NAME_SPACE}/${1}:${2} || exit 1
    echo "Completed to push the ${3} image."
  fi
}

while [[ $# -gt 0 ]]; do
  key="${1}"
    case "${key}" in
      -r | --remove )
        REMOVE=1
        ;;
      -R | --remove-only )
        REMOVE=1
        REMOVE_ONLY=1
        ;;
      -s | --skip-db )
        SKIP_DB=1
        DEPLOY_ON_BUILD=0
        ;;
      -h | --help )
        SHOW_HELP=1
        ;;
      -g )
        GEN_PKG_LIST=1
        ;;
      -c | --use-custom-image )
        USE_CUSTOM_IMAGE=1
        ;;
      -rt | --remove-latest-tag )
        ADD_LATEST_TAG=0
        ;;
      -v | --verbose )
        QUIET=""
        ;;
      -p | --prune )
        PRUNE=1
        ;;
      --deploy-db-on-runtime )
        DEPLOY_ON_BUILD=0
        ;;
      "--push-registry="* )
        REMOTE_REGISTRY="${key#*=}"
        ;;
      "--namespace="* )
        NAME_SPACE="${key#*=}"
        DEFAULT_BUILD_ARGS+=" --build-arg namespace=${NAME_SPACE} "
        ;;
    esac
    shift
done

if [[ ${SHOW_HELP} -eq 1 ]]; then
  cat <<EOF
Usage: build.sh [OPTIONS]

Build Maximo Docker containers.

-r  | --remove                 Remove images when an image exists in repository.
-R  | --remove-only            Remove images without building when an image exists in repository.
-rt | --remove-latest-tag      Do not add the "letest" tag to the built images.
-c  | --use-custom-image       Build a custom image for Maximo installation container.
-v  | --verbose                Show detailed output of the docker build.
-p  | --prune                  Remove intermediate multi-stage builds automatically.
-s  | --skip-db                Skip building and removing a DB image.
--deploy-db-on-runtime         Deploy the Maximo database on runtime.
--push-registry=REGISTRY_URL   Push the built images to a specified remote Docker registry.
--namespace=NAMESPACE          Specify the namespace of the Docker images (default: maximo-liberty).
-h  | --help                   Show this help text.
EOF
  exit 1
fi

cd `dirname "${0}"`

if [[ ${REMOVE} -eq 1 ]]; then
  echo "Remove old images..."
  remove "jmsserver" "${WAS_VER}" "IBM WebSphere Application Server Liberty JMS server"
  remove "maximo-ui" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo UI"
  remove "maximo-api" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo API"
  remove "maximo-cron" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo Crontask"
  remove "maximo-report" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo Report Server"
  remove "maximo-mea" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo MEA"
  remove "maximo-jmsconsumer" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer"
  if [[ ${SKIP_DB} -eq 0 ]]; then
    remove "db2" "${MAXIMO_VER}" "IBM Db2 Advanced Workgroup Server Edition"
  fi
  remove "maximo" "${MAXIMO_VER}" "IBM Maximo Asset Management"
  remove "maximo-base" "${MAXIMO_VER}" "IBM Maximo Asset Management base"
  if [[ ${SKIP_DB} -eq 0 ]]; then
    remove "db2-intermediate" "${MAXIMO_VER}" "IBM Db2 Advanced Workgroup Server Edition - Intermediate Image"
  fi
  remove "liberty" "${WAS_VER}" "IBM WebSphere Application Server Liberty base"
  remove "images" "${MAXIMO_VER}" "Maximo Liberty Docker image container"
#  remove "frontend-proxy" "${PROXY_VER}" "Frontend Proxy Server"

  if [[ ${REMOVE_ONLY} -eq 1 ]]; then
    exit
  fi
fi

# Construct a default build-args
while IFS='=' read -r key value
do
  if [[ "${key}" == "deploy_db_on_build" && ${DEPLOY_ON_BUILD} -eq -1 ]]; then
    if [[ "${value}" == "yes" ]]; then
      DEPLOY_ON_BUILD=1
    else
      DEPLOY_ON_BUILD=0
    fi
  elif [[ "${key}" != "#*" ]]; then
    eval value=${value}
    DEFAULT_BUILD_ARGS+="--build-arg ${key}=${value} "
  fi
done < <(sed --expression="/^#/d" "${DEFAULT_BUILD_ARGS_FILE}")

if [[ ${DEPLOY_ON_BUILD} -eq -1 ]]; then
  DEPLOY_ON_BUILD=1
fi

echo "Start building..."
# Build base image container
build "images" "${MAXIMO_VER}" "images" "Maximo Liberty Docker image Container"

# Build IBM Db2 Advanced Workgroup Edition image
if [[ ${SKIP_DB} -eq 0 ]]; then
  build "db2-intermediate" "${MAXIMO_VER}" "db2" "IBM Db2 Advanced Workgroup Server Edition - Intermediate image"
fi

if [ ${DEPLOY_ON_BUILD} -eq 1 ]; then
  INTERMEDIATE_BUILD_IMAGE_ID="${NAME_SPACE}/db2-intermediate:${MAXIMO_VER}"
  DEPLOY_ON_BUILD_ARG=" --build-arg deploy_db_on_build=yes " 
else
  DEPLOY_ON_BUILD_ARG=" --build-arg deploy_db_on_build=no " 
fi

if [[ ${USE_CUSTOM_IMAGE} -eq 1 ]]; then
  # Build IBM Maximo Asset Management image
  build "maximo-base" "${MAXIMO_VER}" "maximo" "IBM Maximo Asset Management" "--build-arg skip_build=yes --build-arg fp=${FP_VER} --build-arg base_maximo_build=${INTERMEDIATE_BUILD_IMAGE_ID} --build-arg deploy_db_on_build=no"

  # Build IBM Maximo Asset Management Custom image
  build "maximo" "${MAXIMO_VER}" "custom" "IBM Maximo Asset Management Custom Image" "${DEPLOY_ON_BUILD_ARG}"
else
  # Build IBM Maximo Asset Management image
  build "maximo" "${MAXIMO_VER}" "maximo" "IBM Maximo Asset Management" "--build-arg fp=${FP_VER} --build-arg base_maximo_build=${INTERMEDIATE_BUILD_IMAGE_ID} ${DEPLOY_ON_BUILD_ARG}"
fi
push "maximo" "${MAXIMO_VER}" "IBM Maximo Asset Management" 

# Build IBM Db2 Advanced Workgroup Edition image
if [[ ${SKIP_DB} -eq 0 ]]; then
  build "db2" "${MAXIMO_VER}" "maxdb" "IBM Db2 Advanced Workgroup Server Edition"
  push "db2" "${MAXIMO_VER}" "IBM Db2 Advanced Workgroup Server Edition" 
fi

# Build IBM WebSphere Liberty base image
build "liberty" "${WAS_VER}" "liberty" "IBM WebSphere Application Server Liberty base"

# Build IBM WebSphere Liberty JMS server image
build "jmsserver" "${WAS_VER}" "jmsserver" "IBM WebSphere Application Server Liberty JMS server"
push "jmsserver" "${WAS_VER}" "IBM WebSphere Application Server Liberty JMS server"

# Build IBM WebSphere Liberty for Maximo UI image
build "maximo-ui" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo UI" "--build-arg maximoapp=maximo-ui"
push "maximo-ui" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo UI"

# Build IBM WebSphere Liberty for Maximo Crontask image
build "maximo-cron" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Crontask" "--build-arg maximoapp=maximo-cron"
push "maximo-cron" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo Crontask"

# Build IBM WebSphere Liberty for Maximo API image
build "maximo-api" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo API" "--build-arg maximoapp=maximo-api"
push "maximo-api" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo API"

# Build IBM WebSphere Liberty for Maximo Report Server image
build "maximo-report" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Reporting" "--build-arg maximoapp=maximo-report"
push "maximo-report" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo Reporting"

# Build IBM WebSphere Liberty for Maximo MEA image
build "maximo-mea" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo MEA" "--build-arg maximoapp=maximo-mea"
push "maximo-mea" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo MEA"

# Build IBM WebSphere Liberty for JMS Consumer image
build "maximo-jmsconsumer" "${MAXIMO_VER}" "maxapp" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer" "--build-arg maximoapp=maximo-jmsconsumer"
push "maximo-jmsconsumer" "${MAXIMO_VER}" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer"

# Build Frontend Proxy Server
#build "frontend-proxy" "${PROXY_VER}" "frontend-proxy" "Frontend Proxy Server"

# Cleanup Maximo Image build
if [[ ${PRUNE} -eq 1 ]]; then
  echo "Cleanup intermediate images."
  list=$(docker images -q -f "dangling=true" -f "label=autodelete=true")
  if [ -n "${list}" ]; then
      docker rmi $list
  fi 
  
  remove "images" "${MAXIMO_VER}" "Maximo Liberty Docker image container"
fi

echo "Done"
