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

echo "Start initial database configurations."

if ls ${BACKUPDIR}/${MAXDB}.* > /dev/null 2>&1; then
  # Change host name
  db2stop
  HOSTNAME=`hostname -A`
  db2set -g DB2SYSTEM=${HOSTNAME}
  chmod 644 ${DB2_PATH}/db2nodes.cfg
  echo "0 ${HOSTNAME} 0" > ${DB2_PATH}/db2nodes.cfg
  chmod 444 ${DB2_PATH}/db2nodes.cfg

  /bin/bash -c "db2set -null DB2COMM"
  db2start
  until db2gcf -s -t 1 >/dev/null 2>&1; do
    sleep 1
  done

  echo "Restore database ${MAXDB} from ${BACKUPDIR} ..."
  /bin/bash -c "db2 restore database ${MAXDB} from ${BACKUPDIR} without prompting && db2 rollforward database ${MAXDB} to end of logs and stop && db2 terminate"
  db2stop
  rm ${BACKUPDIR}/*
fi
