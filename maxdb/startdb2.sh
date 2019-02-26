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

function sigterm_handler {
su - ctginst1 <<-EOF
  db2 connect to $MAXDB
  db2 terminate
  db2 force applications all
  db2stop force
  ipclean -a
EOF
}

# Change host name
function change_hostname {
su - ctginst1 <<-EOF
  HOSTNAME=`hostname -A`
  db2set -g DB2SYSTEM=$HOSTNAME
  chmod 644 $DB2_PATH/db2nodes.cfg
  echo "0 $HOSTNAME 0" > $DB2_PATH/db2nodes.cfg
  chmod 444 $DB2_PATH/db2nodes.cfg
EOF
}

# Db2 initial setup
function initial_setup {
  # Restore database when a backup image exists
  if [ ! -f /work/db2rfe.cfg ]; then
    echo "Start initial database configurations."
su - ctginst1 <<-EOF
    if ls $BACKUPDIR/$MAXDB.* > /dev/null 2>&1; then
      until db2gcf -s >/dev/null 2>&1; do
        sleep 1
      done

      echo "Restore database from backup..."
      db2 restore database $MAXDB from $BACKUPDIR with 4 buffers buffer 2048 replace existing parallelism 3 without prompting
      db2 terminate
      db2stop
    else
      db2stop
    fi
EOF

    echo "INSTANCENAME=ctginst1" > /work/db2rfe.cfg
    echo "ENABLE_OS_AUTHENTICATION=YES" >> /work/db2rfe.cfg
    echo "RESERVE_REMOTE_CONNECTION=YES" >> /work/db2rfe.cfg
    echo "SVCENAME=db2c_ctginst1" >> /work/db2rfe.cfg
    echo "SVCEPORT=$DB_PORT" >> /work/db2rfe.cfg
    $DB2_PATH/instance/db2rfe -f /work/db2rfe.cfg

su - ctginst1 <<-EOF
    db2 update dbm config using SVCENAME $DB2_PORT
    db2start
EOF
  fi
}

# Change user passwords
echo "ctginst1:$CTGINST1_PASSWORD" | sudo chpasswd
echo "ctgfenc1:$CTGFENC1_PASSWORD" | sudo chpasswd
echo "maximo:$MAXIMO_PASSWORD" | sudo chpasswd

change_hostname

# Start Db2 instance
su - ctginst1 <<-EOF
ipclean -a
db2start
EOF

initial_setup

#cat /home/ctginsti1/sqllib/db2dump/db2diag*

trap sigterm_handler SIGTERM

# Wait until DB2 port is opened
until ncat localhost $DB2_PORT >/dev/null 2>&1; do
  sleep 10
done

while ncat localhost $DB2_PORT >/dev/null 2>&1; do
  sleep 10
done
