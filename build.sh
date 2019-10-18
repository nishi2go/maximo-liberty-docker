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

JMS_OPT="no"
MAXIMO_VER="${MAXIMO_VER:-7.6.1.1}"
IM_VER="${IM_VER:-1.8.8}"
WAS_VER="${WAS_VER:-19.0.0.6-webProfile8}"
DB2_VER="${DB2_VER:-11.1.4a}"
PROXY_VER="${PROXY_VER:-1.8}"

DOCKER="${DOCKER_CMD:-docker}"

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
  $DOCKER build $QUIET $5 --rm $EXTRA_BUILD_ARGS -t $NAME_SPACE/$1:$2 -t $NAME_SPACE/$1:latest $3

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
    esac
    shift
done

if [[ $SHOW_HELP -eq 1 ]]; then
  cat <<EOF
Usage: build.sh [OPTIONS]

-r | --remove           Remove images when an image exists in repository
-J | --disable-jms      Disable JMS configurations in application servers
-v | --verbose          Output verbosity in docker build
-h | --help             Show this help text
EOF
  exit 1
fi

cd `dirname "$0"`

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
  remove "image" "$MAXIMO_VER" "Maximo Liberty Docker image container"
  remove "frontend-proxy" "$PROXY_VER" "Frontend Proxy Server"

  if [[ $REMOVE_ONLY -eq 1 ]]; then
    exit
  fi
fi

echo "Start building..."
# Build base image container
build "images" "$MAXIMO_VER" "images" "Image Container"

# Build IBM Installation Manager image
build "ibmim" "$IM_VER" "ibmim" "IBM Installation Manager"

# Build IBM Maximo Asset Management image
build "maximo" "$MAXIMO_VER" "maximo" "IBM Maximo Asset Management" "--build-arg enablejms=$JMS_OPT"

# Build IBM Db2 Advanced Workgroup Edition image
build "db2" "$DB2_VER" "maxdb" "IBM Db2 Advanced Workgroup Server Edition"

# Build IBM WebSphere Liberty base image
build "liberty" "$WAS_VER" "liberty" "IBM WebSphere Application Server Liberty base"

# Build IBM WebSphere Liberty JMS server image
build "jmsserver" "$WAS_VER" "jmsserver" "IBM WebSphere Application Server Liberty JMS server"

# Build IBM WebSphere Liberty for Maximo UI image
build "maximo-ui" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo UI" "--build-arg maximoapp=maximo-ui"

# Build IBM WebSphere Liberty for Maximo Crontask image
build "maximo-cron" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Crontask" "--build-arg maximoapp=maximo-cron"

# Build IBM WebSphere Liberty for Maximo API image
build "maximo-api" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo API" "--build-arg maximoapp=maximo-api"

# Build IBM WebSphere Liberty for Maximo Report Server image
build "maximo-report" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo Reporting" "--build-arg maximoapp=maximo-report"

# Build IBM WebSphere Liberty for Maximo MEA image
build "maximo-mea" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo MEA" "--build-arg maximoapp=maximo-mea"

# Build IBM WebSphere Liberty for JMS Consumer image
build "maximo-jmsconsumer" "$MAXIMO_VER" "maxapp" "IBM WebSphere Application Server Liberty for Maximo JMS Consumer" "--build-arg maximoapp=maximo-jmsconsumer"

# Build Frontend Proxy Server
build "frontend-proxy" "$PROXY_VER" "frontend-proxy" "Frontend Proxy Server"

echo "Done"
