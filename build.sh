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

IMAGE_DIR=
CHECK_DIR=
JMS_OPT="no"
PACKAGE_LIST=packages.list
MAXIMO_VER="${MAXIMO_VER:-7.6.1.1}"
IM_VER="${IM_VER:-1.8.8}"
WAS_VER="${WAS_VER:-19.0.0.6-webProfile8}"
DB2_VER="${DB2_VER:-11.1.4a}"
PROXY_VER="${PROXY_VER:-1.8}"

DOCKER="${DOCKER_CMD:-docker}"

BUILD_NETWORK_NAME="maximo-liberty-build"
IMAGE_SERVER_NAME="liberty-images"
IMAGE_SERVER_HOST_NAME="liberty-images"
NAME_SPACE="maximo-liberty"

REMOVE=0
JMS_OPT="yes"
QUIET=-q

# Usage: remove "tag name" "version" "product name"
function remove {
  image_id=`$DOCKER images -q --no-trunc $NAME_SPACE/$1:$2`
  if [[ ! -z "$image_id" ]]; then
    echo "An old $3 image exists. Remove it."
    container_ids=`$DOCKER ps -aq --no-trunc -f ancestor=$image_id`
    if [[ ! -z "$container_ids" ]]; then
      $DOCKER rm -f $container_ids
    fi
    $DOCKER rmi -f "$image_id"
  fi
}

# Usage: build "tag name" "version" "target directory name" "product name"
function build {
  echo "Start to build $4 image"
  $DOCKER build $QUIET $5 --rm $EXTRA_BUILD_ARGS -t $NAME_SPACE/$1:$2 -t $NAME_SPACE/$1:latest --network $BUILD_NETWORK_NAME $3

  exists=`$DOCKER images -q --no-trunc $NAME_SPACE/$1:$2`
  if [[ -z "$exists" ]]; then
    echo "Failed to create $4 image."
    exit 2
  fi
  echo "Completed $4 image creation."
}

while [[ $# -gt 0 ]]; do
  key="$1"
    case "$key" in
      -c | --check )
        CHECK=1
        ;;
      -C | --deepcheck )
        CHECK=1
        DEEP_CHECK=1
        ;;
      -d | --check-dir )
        shift
        CHECK_DIR="$1"
        ;;
      -J | --disable-jms )
        JMS_OPT="no"
        ;;
      -r | --remove )
        REMOVE=1
        ;;
      -R | --remove-only )
        REMOVE=1
        REMOVE_ONLY=1
        ;;
      -h | --help )
        SHOW_HELP=1
        ;;
      -g )
        GEN_PKG_LIST=1
        ;;
      -v | --verbose )
        QUIET=""
        ;;
      * )
        IMAGE_DIR="$1"
        if [[ -z "$CHECK_DIR" ]]; then
          CHECK_DIR=$IMAGE_DIR
        fi
    esac
    shift
done

if [[ $SHOW_HELP -eq 1 || -z "$IMAGE_DIR" ]]; then
  cat <<EOF
Usage: build.sh [OPTIONS] [DIR]

-c | --check            Check required packages
-C | --deepcheck        Check and compare checksum of required packages
-r | --remove           Remove images when an image exists in repository
-J | --disable-jms      Disable JMS configurations in application servers
-d | --check-dir [DIR]  The directory for validating packages (Docker for Windows only)
-v | --verbose          Output verbosity in docker build
-h | --help             Show this help text
EOF
  exit 1
fi

cd `dirname "$0"`

if [[ $GEN_PKG_LIST -eq 1 ]]; then
  rm $PACKAGE_LIST.out
fi

if [[ $CHECK -eq 1 ]]; then
  echo "Start to check packages"
  if [[ ! -d "$CHECK_DIR" ]]; then
    echo "The specified directory could not access"
    exit 9
  fi

  while IFS=, read -r file md5sum; do
   echo -n -e "Check $file exists...\t"
   if [[ ! -f "$CHECK_DIR/$file" ]]; then
     echo " Not found."
     exit 9
   fi

   if [[ $DEEP_CHECK -eq 1 ]]; then
     res=`md5sum $CHECK_DIR/$file`
     if [[ $GEN_PKG_LIST -eq 1 ]]; then
       echo "$file,$res" >> $PACKAGE_LIST.out
     elif [[ "$md5sum" == "$res" ]]; then
       echo " MD5 does not match."
       exit 9
     fi
   fi

   echo " Found."
  done < $PACKAGE_LIST
fi

if [[ $REMOVE -eq 1 ]]; then
  echo "Remove old images..."
  remove "db2" "$DB2_VER" "IBM Db2 Advanced Workgroup Server Edition"
  remove "maximo" "$MAXIMO_VER" "IBM Maximo Asset Management"
  remove "jmsserver" "$WAS_VER" "IBM WebSphere Application Server Liberty JMS server"
  remove "maximo-ui" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo UI"
  remove "maximo-api" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo API"
  remove "maximo-cron" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo Crontask"
  remove "maximo-report" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo Report Server"
  remove "maximo-mea" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo MEA"
  remove "maximo-jmsconsumer" "$MAXIMO_VER" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer"
  remove "liberty" "$WAS_VER" "IBM WebSphere Application Server Liberty base"
  remove "ibmim" "$IM_VER" "IBM Installation Manager"
  remove "frontend-proxy" "$PROXY_VER" "Frontend Proxy Server"

  if [[ $REMOVE_ONLY -eq 1 ]]; then
    exit
  fi
fi

echo "Start to build..."

# Create a newwork for build if it does not exist
if [[ -z `$DOCKER network ls -q --no-trunc -f "name=^${BUILD_NETWORK_NAME}$"` ]]; then
  echo "Docker network build does not exist. Start to make it."
  $DOCKER network create ${BUILD_NETWORK_NAME}
  $DOCKER network ls -f "name=^${BUILD_NETWORK_NAME}$"
fi

# Remove and run a container for HTTP server
images_exists=`$DOCKER ps -aq --no-trunc -f "name=^/${IMAGE_SERVER_NAME}$"`
if [[ ! -z "$images_exists" ]]; then
    echo "Docker container ${IMAGE_SERVER_NAME} has been started. Remove it."
    $DOCKER rm -f "$images_exists"
fi

echo "Start a container - ${IMAGE_SERVER_NAME}"
$DOCKER run --rm --name ${IMAGE_SERVER_NAME} -h ${IMAGE_SERVER_HOST_NAME} \
 --network ${BUILD_NETWORK_NAME} -v "${IMAGE_DIR}":/usr/share/nginx/html:ro -d nginx
$DOCKER ps -f "name=^/${IMAGE_SERVER_NAME}"

sleep 1

# Build IBM Installation Manager image
build "ibmim" "$IM_VER" "ibmim" "IBM Installation Manager"

# Build IBM Maximo Asset Management image
build "maximo" "$MAXIMO_VER" "maximo" "IBM Maximo Asset Management" "--build-arg enablejms=$JMS_OPT"

# Build IBM Db2 Advanced Workgroup Edition image
build "db2" "$DB2_VER" "maxdb" "IBM Db2 Advanced Workgroup Server Edition"

# Build IBM WebSphere Liberty base image
build "liberty" "$WAS_VER" "liberty" "IBM WebSphere Application Server Liberty base" "--build-arg libertyver=$WAS_VER"

# Build IBM WebSphere Liberty JMS server image
build "jmsserver" "$WAS_VER" "jmsserver" "IBM WebSphere Application Server Liberty JMS server"

# Build IBM WebSphere Liberty for Maximo UI image
build "maximo-ui" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo UI" "--build-arg maximoapp=maximo-ui"

# Build IBM WebSphere Liberty for Maximo Crontask image
build "maximo-cron" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Crontask" "--build-arg maximoapp=maximo-cron"

# Build IBM WebSphere Liberty for Maximo API image
build "maximo-api" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo API" "--build-arg maximoapp=maximo-api"

# Build IBM WebSphere Liberty for Maximo Report Server image
build "maximo-report" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Report" "--build-arg maximoapp=maximo-report"

# Build IBM WebSphere Liberty for Maximo MEA image
build "maximo-mea" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo MEA" "--build-arg maximoapp=maximo-mea"

# Build IBM WebSphere Liberty for Maximo Report Server image
build "maximo-jmsconsumer" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer" "--build-arg maximoapp=maximo-jmsconsumer"

# Build Frontend Proxy Server
build "frontend-proxy" "$PROXY_VER" "frontend-proxy" "Frontend Proxy Server"

echo "Stop the images container - ${IMAGE_SERVER_NAME}"
$DOCKER stop ${IMAGE_SERVER_NAME}

echo "Done"
