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

# Set up function for deploy on build
function deploy_on_build_set_up {
  export MXINTADM_PASSWORD=${mxintadm_password}
  export MAXADMIN_PASSWORD=${maxadmin_password}
  export MAXREG_PASSWORD=${maxreg_password}
  export MAXDB_SERVICE_HOST=localhost
  export MAXDB_SERVICE_HOST_IP=127.0.0.1
  export JDBC_URL=jdbc:db2://localhost:${MAXDB_SERVICE_PORT}/${MAXDB}
  export DB_TABLE_SPACE=MAXDATA
  export DB_TEMP_SPACE=MAXTEMP
  export DB_INDEX_SPACE=MAXINDEX
  export DB_VENDOR=DB2
  export DB_MAXIMO_PASSWORD=${db_maximo_password}
  export BASE_LANG=${base_lang}
  export ADD_LANGS=${add_langs}
  export ADMIN_EMAIL_ADDRESS=${admin_email_address}
  export SMTP_SERVER_HOST_NAME=${smtp_server_host_name}
  export SKIN=${skin}

  cat ${CONFIG_FILE_TEMPLATE} | envsubst >${CONFIG_FILE}

  su - ctginst1 <<-EOS
    HOSTNAME=$(hostname -A)
    db2set -g DB2SYSTEM=${HOSTNAME}
    chmod 644 ${DB2_PATH}/db2nodes.cfg
    echo "0 ${HOSTNAME} 0" > ${DB2_PATH}/db2nodes.cfg
    chmod 444 ${DB2_PATH}/db2nodes.cfg
EOS

  echo "INSTANCENAME=ctginst1" >/work/db2/db2rfe.cfg
  echo "ENABLE_OS_AUTHENTICATION=YES" >>/work/db2/db2rfe.cfg
  echo "RESERVE_REMOTE_CONNECTION=YES" >>/work/db2/db2rfe.cfg
  echo "SVCENAME=db2c_ctginst1" >>/work/db2/db2rfe.cfg
  echo "SVCEPORT=${db_port}" >>/work/db2/db2rfe.cfg
  ${DB2_PATH}/instance/db2rfe -f /work/db2/db2rfe.cfg

  echo "maximo:${db_maximo_password}" | sudo chpasswd

  su - ctginst1 <<-EOS
  db2set DB2COMM=tcpip
  ${DB2_PATH}/adm/db2start

  until db2 "connect to ${MAXDB} user maximo using ${db_maximo_password}"; do
    sleep 1
  done
EOS

  rm /work/db2/db2rfe.cfg
}

# Take a backup for the later process
function backup_db {
  mkdir -p ${BACKUP_DIR}
  chown ctginst1.ctggrp1 ${BACKUP_DIR}
  rm ${BACKUP_DIR}/*

  su - ctginst1 <<-EOS
    db2 CONNECT TO ${MAXDB}
    db2 QUIESCE DATABASE IMMEDIATE FORCE CONNECTIONS
    db2 CONNECT RESET
    db2 BACKUP DATABASE ${MAXDB} TO ${BACKUP_DIR} WITH 4 BUFFERS BUFFER 2048 PARALLELISM 2 COMPRESS WITHOUT PROMPTING
    db2 CONNECT TO ${MAXDB}
    db2 UNQUIESCE DATABASE
    db2 CONNECT RESET

    db2set -null DB2COMM
EOS
}

# Clear old deployment files first
SMP="/opt/IBM/SMP"

mkdir -p ${MAXIMO_DIR}

if [ -f "${MAXIMO_DIR}/maximo.properties" ]; then
  rm "${MAXIMO_DIR}/maximo.properties"
fi

if [[ "${ENABLE_DEMO_DATA}" == "yes" ]]; then
  DEMO_DATA="-deployDemoData"
fi

APP_SECURITY=""
if [[ "${USE_APP_SERVER_SECURITY}" == "yes" ]]; then
  APP_SECURITY="-enableappsecurity -usermanagement ${USER_MANAGEMENT}"
fi

#copy skel files
CONFIG_FILE=/opt/maximo-config.properties
CONFIG_FILE_TEMPLATE=${CONFIG_FILE}.template

if [[ "${deploy_db_on_build}" == "yes" ]]; then
  deploy_on_build_set_up
else
  # Watch and wait the database
  wait-for-it.sh ${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT} -t 0 -q -- echo "Database is ready."
  export MAXDB_SERVICE_HOST_IP=$(ping ${MAXDB_SERVICE_HOST} -c 1 | head -n 2 | tail -n 1 | cut -f 4 -d ' ' | tr -d ':')

  if [ "${DB_VENDOR}" == "Oracle" ]; then
    export JDBC_URL="jdbc:oracle:thin:@${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
  fi
  if [ "${DB_VENDOR}" == "DB2" ]; then
    export JDBC_URL="jdbc:db2://${MAXDB_SERVICE_HOST}:${MAXDB_SERVICE_PORT}/${MAXDB}"
  fi
fi

if [[ ! -f "${CONFIG_FILE}" || "${deploy_db_on_build}" == "yes" ]]; then
  cat ${CONFIG_FILE_TEMPLATE} | envsubst >${CONFIG_FILE}

  # Run Configuration Tool
  $SMP/ConfigTool/scripts/reconfigurePae.sh -action deployConfiguration \
    -bypassJ2eeValidation -inputfile "${CONFIG_FILE}" "${DEMO_DATA}" "${APP_SECURITY}"
else
  echo "Maximo has already configured."
fi

INSTALL_PROPERTIES=${SMP}/etc/install.properties
sed -ie "s/^ApplicationServer.Vendor=.*/ApplicationServer.Vendor=WebSphereLiberty/" "${INSTALL_PROPERTIES}"

$SMP/ConfigTool/scripts/reconfigurePae.sh -action updateApplicationDBLite \
  -updatedb -enableSkin "${SKIN}" -enableEnhancedNavigation

# Deploy WAS.UserName and WAS.Password properties
#cd $SMP/maximo/tools/maximo/internal && ./runscriptfile.sh -cliberty -fliberty

if [[ "${deploy_db_on_build}" == "yes" ]]; then
  backup_db
else
  # Fix IP address issue
  MAXIMO_PROPERTIES=${SMP}/maximo/applications/maximo/properties/maximo.properties
  cp "${MAXIMO_PROPERTIES}" "${MAXIMO_DIR}" && chmod 444 "${MAXIMO_DIR}/maximo.properties"
fi

if [ "${KEEP_RUNNING}" == "yes" ]; then
  sleep inf &
  child=$!
  wait ${child}
fi
