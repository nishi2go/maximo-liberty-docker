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

if [ "${skip_build}" = "yes" ]
then
  echo "Skip building war files."
  exit
fi

function jvm_config {
  jvm_config_path=$1
  cp "${jvm_config_path}.orig" "${jvm_config_path}.tmp"

  echo "-Xdisableexplicitgc" >> "${jvm_config_path}.tmp"
  echo "-Xcompressedrefs" >> "${jvm_config_path}.tmp"
  echo "-XX:+UseContainerSupport" >> "${jvm_config_path}.tmp"
  echo "-Xgc:concurrentScavenge" >> "${jvm_config_path}.tmp"
  echo "-XX:+ExitOnOutOfMemoryError" >> "${jvm_config_path}.tmp"
  echo "-Dmxe.properties.overridepath=/config/maximo.properties" >> "${jvm_config_path}.tmp"

  cp "${jvm_config_path}.tmp" "${jvm_config_path}"
  rm "${jvm_config_path}.tmp"
}

function add_app_server_security_web_xml {
  xml_path=$1
  type=$2

  cp "${xml_path}.orig" "${xml_path}.tmp"

  # Enable app server security
  xmlstarlet ed -L -N x="http://java.sun.com/xml/ns/j2ee" \
    -u '/x:web-app/x:env-entry/x:env-entry-name[text()="useAppServerSecurity"]/../x:env-entry-value' \
    -v "1" "${xml_path}.tmp"

  sed -i -e "/<\/web-app>$/d" "${xml_path}.tmp"
  cat "/work/ldap-config/${type}.xml" >> "${xml_path}.tmp"
  echo "</web-app>" >> "${xml_path}.tmp"

  xmlstarlet fo "${xml_path}.tmp" > "${xml_path}"

  rm "${xml_path}.tmp"

  #debug
  # cat "${xml_path}"
}

function edit_server_xml {
  xml_path=$1
  cp "${xml_path}.orig" "${xml_path}.tmp"

  # Remove Java EE 7 features
  for feat in "jdbc-4.1" "webProfile-7.0" "javaMail-1.5"
  do
    sed -i -e "/$feat/d" "${xml_path}.tmp"
  done

  # Remove comment out
  sed -i 's/[ \t]\+$//' "${xml_path}.tmp"
  sed -i -e '/<!--$/d' "${xml_path}.tmp"
  sed -i -e '/^-->$/d' "${xml_path}.tmp"

  # Add quicksecuriy
  xmlstarlet ed -L \
    -s "/server" -t elem -n "quickStartSecurity" -v "" \
    -a "/server/quickStartSecurity" -t attr -n "userName" -v '${env.ADMIN_USER_NAME}' \
    -a "/server/quickStartSecurity" -t attr -n "userPassword" -v '${env.ADMIN_PASSWORD}' \
    -s "/server/featureManager" -t elem -n "feature" -v "localConnector-1.0" \
    -s "/server/featureManager" -t elem -n "feature" -v "ejbHome-3.2" \
     "${xml_path}.tmp"

  if [ "${USE_APP_SERVER_SECURITY}" = "yes" ]
  then
    # Add ldapRegistry
    xmlstarlet ed -L \
      -s "/server" -t elem -n "include" -v "" \
      -s "/server/include" -t attr -n "location" -v '${server.config.dir}/ldapUserRegistry.xml' \
      -s "/server/featureManager" -t elem -n "feature" -v "ldapRegistry-3.0" \
      -s "/server/featureManager" -t elem -n "feature" -v "appSecurity-2.0" \
      -s "/server/featureManager" -t elem -n "feature" -v "transportSecurity-1.0" \
      -u "/server/webAppSecurity/@ssoRequiresSSL" -v "false" \
      -u "/server/application/application-bnd/security-role[@name='any-authenticated']/@name" -v "AllAuthenticated" \
      -u "/server/application/application-bnd/security-role[@name='everyone']/@name" -v "maximouser" \
      -d "/server/application/application-bnd/security-role[@name='maximouser']/*" \
      -s "/server/application/application-bnd/security-role[@name='maximouser']" -t elem -n "group" -v "" \
      -s "/server/application/application-bnd/security-role[@name='maximouser']/group" -t attr -n "name" -v "maximousers" \
      "${xml_path}.tmp"
  fi

  if [ "${JMS_ENABLED}" = "no" ]
  then
    xmlstarlet ed -L -d "//jmsQueue" \
      -d "//jmsQueueConnectionFactory" \
      -d "//connectionManager" "${xml_path}.tmp"
  else
    xmlstarlet ed -L -u "//properties.wasJms/@remoteServerAddress" \
     -v '${env.MAXIMO_JMS_SERVICE_HOST}:${env.MAXIMO_JMS_SERVICE_PORT}:BootstrapBasicMessaging' "${xml_path}.tmp"
  fi

  xmlstarlet fo "${xml_path}.tmp" > "${xml_path}"

  rm "${xml_path}.tmp"

  #debug
  # cat "${xml_path}"
}

SMP="/opt/IBM/SMP"

# Run updatedblitepreprocessor
touch "${SMP}/maximo/applications/maximo/properties/maximo.properties"
cd "${SMP}/maximo/tools/maximo"
./updatedblitepreprocessor.sh || exit 1

LIBERTY_DEF_DIR="${SMP}/maximo/deployment/was-liberty-default"
cd ${LIBERTY_DEF_DIR}

# Transform java ee 7 config to java ee 8 config in server.xml
for dir in "maximo-api" "maximo-cron" "maximo-jmsconsumer" "maximo-mea" "maximo-report" "maximo-ui"
do
  SERVER_XML="${LIBERTY_DEF_DIR}/config-servers/${dir}/${dir}-server/server.xml"
  if [ ! -f "${SERVER_XML}.orig" ]
  then
    cp "${SERVER_XML}" "${SERVER_XML}.orig"
  fi

  edit_server_xml "${SERVER_XML}"

  JVM_OPTIONS="${LIBERTY_DEF_DIR}/config-servers/${dir}/${dir}-server/jvm.options"
  if [ ! -f "${JVM_OPTIONS}.orig" ]
  then
    cp "${JVM_OPTIONS}" "${JVM_OPTIONS}.orig"
  fi

  jvm_config "${JVM_OPTIONS}"
done

if [ "${USE_APP_SERVER_SECURITY}" = "yes" ]
then
  WEB_XML="${LIBERTY_DEF_DIR}/config-deployment-descriptors/maximo-mea/meaweb/webmodule/WEB-INF/web.xml"
  if [ ! -f "${WEB_XML}.orig" ]
  then
    cp "${WEB_XML}" "${WEB_XML}.orig"
  fi

  add_app_server_security_web_xml "${WEB_XML}" "maximo-mea"
 
  for dir in "maximo-api" "maximo-report" "maximo-ui"
  do
    WEB_XML="${LIBERTY_DEF_DIR}/config-deployment-descriptors/${dir}/webmodule/WEB-INF/web.xml"
    if [ ! -f "${WEB_XML}.orig" ]
    then
      cp "${WEB_XML}" "${WEB_XML}.orig"
    fi

    add_app_server_security_web_xml "${WEB_XML}" "${dir}"
  done
fi

if [ "${JMS_ENABLED}" = "yes" ]
then
  EJB_XMI="${LIBERTY_DEF_DIR}/config-deployment-descriptors/maximo-jmsconsumer/mboejb/ejbmodule/META-INF/ibm-ejb-jar-bnd.xmi"
  sed -i -e '/^-->$/d' "${EJB_XMI}"
  sed -i -e 's/^<!--/& -->/g' "${EJB_XMI}"
fi

cd "${LIBERTY_DEF_DIR}"

# Compile war files
for type in "-xwar" "api-war" "cron-war" "jmsconsumer-ear" "mea-ear" "report-war" "ui-war"
do
  echo "Run buildmaximo${type}.sh ..."
  bash "buildmaximo${type}.sh"
done
