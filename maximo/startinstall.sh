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

if [ -f "$MAXIMO_DIR/maximo.properties" ]
then
  rm "$MAXIMO_DIR/maximo.properties"
fi

# Watch and wait the database
wait-for-it.sh $DB_HOST_NAME:$DB_PORT -t 0 -q -- echo "Database is up"

if [[ ! -z "$ENABLE_DEMO_DATA" && "$ENABLE_DEMO_DATA" = "yes" ]]
then
  DEMO_DATA="-deployDemoData"
fi

#copy skel files
CONFIG_FILE=/opt/maximo-config.properties
if [ -f $CONFIG_FILE ]
then
  echo "Maximo has already configured."
else
  cat > $CONFIG_FILE <<EOF
MW.Operation=Configure
# Maximo Configuration Parameters
mxe.adminuserloginid=maxadmin
mxe.adminPasswd=$MAXADMIN_PASSWORD
mxe.system.reguser=maxreg
mxe.system.regpassword=$MAXREG_PASSWORD
mxe.int.dfltuser=mxintadm
maximo.int.dfltuserpassword=$MXINTADM_PASSWORD
MADT.NewBaseLang=$BASE_LANG
MADT.NewAddLangs=$ADD_LANGS
mxe.adminEmail=$ADMIN_EMAIL_ADDRESS
mail.smtp.host=$SMTP_SERVER_HOST_NAME
mxe.db.user=maximo
mxe.db.password=$DB_MAXIMO_PASSWORD
mxe.db.schemaowner=maximo
mxe.useAppServerSecurity=0

# Database Configuration Parameters
Database.UserSpecifiedJDBCURL=jdbc:db2://$DB_HOST_NAME:$DB_PORT/$MAXDB
Database.AutomateConfig=false
Database.Vendor=DB2
Database.DB2.DatabaseName=$MAXDB
Database.DB2.ServerHostName=$DB_HOST_NAME
Database.DB2.ServerPort=$DB_PORT
Database.DB2.DataTablespaceName=MAXDATA
Database.DB2.TempTablespaceName=MAXTEMP
Database.DB2.Vargraphic=true
Database.DB2.TextSearchEnabled=false

# WebSphere Configuration Parameters
ApplicationServer.Vendor=WebSphere
WAS.ND.AutomateConfig=false
IHS.AutomateConfig=false
WAS.ClusterAutomatedConfig=false
WAS.DeploymentManagerRemoteConfig=false
EOF

  # Run Configuration Tool
  $SMP/ConfigTool/scripts/reconfigurePae.sh -action deployConfiguration \
    -bypassJ2eeValidation -inputfile $CONFIG_FILE $DEMO_DATA
fi

INSTALL_PROPERTIES=$SMP/etc/install.properties
sed -ie "s/^ApplicationServer.Vendor=.*/ApplicationServer.Vendor=WebSphereLiberty/" "$INSTALL_PROPERTIES"

$SMP/ConfigTool/scripts/reconfigurePae.sh -action updateApplicationDBLite \
  -updatedb -enableSkin "$SKIN" -enableEnhancedNavigation

# Deploy WAS.UserName and WAS.Password properties
cd $SMP/maximo/tools/maximo/internal && ./runscriptfile.sh -cliberty -fliberty

# Fix IP address issue
MAXIMO_PROPERTIES=$SMP/maximo/applications/maximo/properties/maximo.properties
cp $MAXIMO_PROPERTIES $MAXIMO_DIR && chmod 444 $MAXIMO_DIR/maximo.properties
