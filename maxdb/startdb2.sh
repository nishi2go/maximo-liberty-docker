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

. ${DB2_PATH}/db2profile

function sigterm_handler {
  db2 connect to ${MAXDB}
  db2 terminate
  db2 force applications all
  db2stop force
  ipclean -a
}

# Change host name
function change_hostname {
  db2stop
  HOSTNAME=`hostname -A`
  db2set -g DB2SYSTEM=${HOSTNAME}
  chmod 644 ${DB2_PATH}/db2nodes.cfg
  echo "0 ${HOSTNAME} 0" > ${DB2_PATH}/db2nodes.cfg
  chmod 444 ${DB2_PATH}/db2nodes.cfg
}

# Db2 initial setup
function initial_setup {
  # Restore database when a backup image exists
  if [ ! -f /work/db2/db2rfe.cfg ]; then
    echo "Run db2rfe command."
    echo "INSTANCENAME=ctginst1" > /work/db2/db2rfe.cfg
    echo "ENABLE_OS_AUTHENTICATION=YES" >> /work/db2/db2rfe.cfg
    echo "RESERVE_REMOTE_CONNECTION=YES" >> /work/db2/db2rfe.cfg
    echo "SVCENAME=db2c_ctginst1" >> /work/db2/db2rfe.cfg
    echo "SVCEPORT=${MAXDB_SERVICE_PORT}" >> /work/db2/db2rfe.cfg
    sudo ${DB2_PATH}/instance/db2rfe -f /work/db2/db2rfe.cfg

    echo "Start initial database configurations."
    if ls ${BACKUPDIR}/${MAXDB}.* > /dev/null 2>&1; then
      /bin/bash -c "db2set -null DB2COMM"
      db2start
      until db2gcf -s -t 1 >/dev/null 2>&1; do
        sleep 1
      done

      echo "Restore database ${MAXDB} from ${BACKUPDIR} ..."
      /bin/bash -c "db2 restore database ${MAXDB} from ${BACKUPDIR} with 4 buffers buffer 2048 replace existing parallelism 3 without prompting && db2 rollforward database ${MAXDB} complete && db2 terminate"
      db2stop
      echo "Done."
    fi
    /bin/bash -c "db2set DB2COMM=tcpip"
  fi
}

# Change user passwords
echo "maximo:${DB_MAXIMO_PASSWORD}" | sudo chpasswd

change_hostname
initial_setup

# Start Db2 instance
ipclean -a
db2start

trap sigterm_handler SIGTERM

# Wait until DB2 port is opened
until ncat localhost ${MAXDB_SERVICE_PORT} >/dev/null 2>&1; do
  sleep 10
done

while ncat localhost ${MAXDB_SERVICE_PORT} >/dev/null 2>&1; do
  sleep 10
done
