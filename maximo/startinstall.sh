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

# Clear old deployment files first
SMP="/opt/IBM/SMP"

mkdir -p ${MAXIMO_DIR}

if [ -f "${MAXIMO_DIR}/maximo.properties" ]
then
  rm "${MAXIMO_DIR}/maximo.properties"
fi

# Watch and wait the database
wait-for-it.sh ${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT} -t 0 -q -- echo "Database is ready."
export MAXDB_SERVICE_HOST_IP=`ping ${MAXDB_SERVICE_HOST} -c 1 | head -n 2 | tail -n 1 | cut -f 4 -d ' ' | tr -d ':'`

if [[ ! -z "${ENABLE_DEMO_DATA}" && "${ENABLE_DEMO_DATA}" = "yes" ]]
then
  DEMO_DATA="-deployDemoData"
fi

#copy skel files
CONFIG_FILE=/opt/maximo-config.properties
CONFIG_FILE_TEMPLATE=${CONFIG_FILE}.template

if [ "${DB_VENDOR}" == "Oracle" ]
then
  export JDBC_URL="jdbc:oracle:thin:@${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
fi
if [ "${DB_VENDOR}" == "DB2" ]
then
  export JDBC_URL="jdbc:db2://${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
fi

if [ -f ${CONFIG_FILE} ]
then
  echo "Maximo has already configured."
else
  cat ${CONFIG_FILE_TEMPLATE}| envsubst > ${CONFIG_FILE}
  
  # Run Configuration Tool
  $SMP/ConfigTool/scripts/reconfigurePae.sh -action deployConfiguration \
    -bypassJ2eeValidation -inputfile "${CONFIG_FILE}" "${DEMO_DATA}"
fi

INSTALL_PROPERTIES=${SMP}/etc/install.properties
sed -ie "s/^ApplicationServer.Vendor=.*/ApplicationServer.Vendor=WebSphereLiberty/" "${INSTALL_PROPERTIES}"

$SMP/ConfigTool/scripts/reconfigurePae.sh -action updateApplicationDBLite \
  -updatedb -enableSkin "${SKIN}" -enableEnhancedNavigation

# Deploy WAS.UserName and WAS.Password properties
#cd $SMP/maximo/tools/maximo/internal && ./runscriptfile.sh -cliberty -fliberty

# Fix IP address issue
MAXIMO_PROPERTIES=${SMP}/maximo/applications/maximo/properties/maximo.properties
cp ${MAXIMO_PROPERTIES} ${MAXIMO_DIR} && chmod 444 ${MAXIMO_DIR}/maximo.properties

if [ "${KEEP_RUNNING}" == "yes" ]
then
  sleep inf &
  child=$!
  wait ${child}
fi