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

terminate_handler()
{
  echo "Terminating the Maximo server..."
  /opt/ibm/wlp/bin/server stop defaultServer
}

trap die SIGTERM

if [[ "${JVM_HEAP_MIN_SIZE}" != "" ]]
then
  echo "-Xms${JVM_HEAP_MIN_SIZE}" >> /config/jvm.options
fi

if [[ "${JVM_HEAP_MAX_SIZE}" != "" ]]
then
  echo "-Xmx${JVM_HEAP_MAX_SIZE}" >> /config/jvm.options
fi

if [[ "${GEN_MAXIMO_PROPERTIES}" != "yes" ]]
then
  until [[ -f "${MAXIMO_DIR}/maximo.properties" ]]
  do
    sleep 1
  done

  cp "${MAXIMO_DIR}/maximo.properties" /config/
else
  wait-for-it.sh ${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT} -t 0 -q -- echo "Database is ready."

  if [[ -z "${JDBC_URL}" && "${DB_VENDOR}" == "Oracle" ]]
  then
      export JDBC_URL="jdbc:oracle:thin:@${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
  fi
  if [[ -z "${JDBC_URL}" && "${DB_VENDOR}" == "DB2" ]]
  then
      export JDBC_URL="jdbc:db2://${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
  fi

  cat "${MAXIMO_DIR}/maximo.properties.template" | envsubst > /config/maximo.properties
fi

if [[ -z "${LIBERTY_CMD}" ]]
then
  LIBERTY_CMD=run
fi

exec /opt/ibm/wlp/bin/server ${LIBERTY_CMD} defaultServer
