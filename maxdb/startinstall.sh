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

if [[ ! -z "${enable_demo_data}" && "${enable_demo_data}" = "yes" ]]
then
  DEMO_DATA="-deployDemoData"
fi

#copy skel files
export MXINTADM_PASSWORD=${mxintadm_password}
export MAXADMIN_PASSWORD=${maxadmin_password}
export MAXREG_PASSWORD=${maxreg_password}
export MAXDB_SERVICE_HOST=localhost
export DB_MAXIMO_PASSWORD=${db_maximo_password}
export BASE_LANG=${base_lang}
export ADD_LANGS=${add_langs}
export ADMIN_EMAIL_ADDRESS=${admin_email_address}
export SMTP_SERVER_HOST_NAME=${smtp_server_host_name}
export SKIN=${skin}

CONFIG_FILE=/opt/maximo-config.properties
CONFIG_FILE_TEMPLATE=${CONFIG_FILE}.template
cat ${CONFIG_FILE_TEMPLATE} | envsubst > ${CONFIG_FILE}

su - ctginst1 <<- EOS
  HOSTNAME=`hostname -A`
  db2set -g DB2SYSTEM=${HOSTNAME}
  chmod 644 ${DB2_PATH}/db2nodes.cfg
  echo "0 ${HOSTNAME} 0" > ${DB2_PATH}/db2nodes.cfg
  chmod 444 ${DB2_PATH}/db2nodes.cfg
EOS

echo "INSTANCENAME=ctginst1" > /work/db2/db2rfe.cfg
echo "ENABLE_OS_AUTHENTICATION=YES" >> /work/db2/db2rfe.cfg
echo "RESERVE_REMOTE_CONNECTION=YES" >> /work/db2/db2rfe.cfg
echo "SVCENAME=db2c_ctginst1" >> /work/db2/db2rfe.cfg
echo "SVCEPORT=${db_port}" >> /work/db2/db2rfe.cfg
${DB2_PATH}/instance/db2rfe -f /work/db2/db2rfe.cfg

echo "maximo:${db_maximo_password}" | sudo chpasswd

su - ctginst1 <<- EOS
 db2set DB2COMM=tcpip
 ${DB2_PATH}/adm/db2start

 until db2 "connect to ${MAXDB} user maximo using ${db_maximo_password}"; do
   sleep 1
 done
EOS

rm /work/db2/db2rfe.cfg

# Run Configuration Tool
export BYPASS_PRS=True
${SMP}/ConfigTool/scripts/reconfigurePae.sh -action deployConfiguration \
  -bypassJ2eeValidation -inputfile "${CONFIG_FILE}" "${DEMO_DATA}"

INSTALL_PROPERTIES=${SMP}/etc/install.properties
sed -ie "s/^ApplicationServer.Vendor=.*/ApplicationServer.Vendor=WebSphereLiberty/" "${INSTALL_PROPERTIES}"

${SMP}/ConfigTool/scripts/reconfigurePae.sh -action updateApplicationDBLite \
  -updatedb -enableSkin "${skin}" -enableEnhancedNavigation || exit 1

# Take a backup for the later process
su - ctginst1 <<- EOS
 db2 CONNECT TO ${MAXDB}
 db2 QUIESCE DATABASE IMMEDIATE FORCE CONNECTIONS
 db2 CONNECT RESET
 db2 BACKUP DATABASE ${MAXDB} TO /work/backup WITH 4 BUFFERS BUFFER 2048 PARALLELISM 2 COMPRESS WITHOUT PROMPTING
 db2 CONNECT TO ${MAXDB}
 db2 UNQUIESCE DATABASE
 db2 CONNECT RESET

 db2set -null DB2COMM
EOS
