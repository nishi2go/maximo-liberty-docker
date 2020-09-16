# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The script is used for customizing Maximo image e.g. to install Industry Solutions, your custom java classes and etc.

ARG buildver=7.6.1.2

FROM maximo-liberty/images:${buildver}

FROM maximo-liberty/maximo-base:${buildver}

## Put the custom installation here or remove comments
## Sample scripts for Oil & Gas Industry Solution
#RUN mkdir /work/oag
#WORKDIR /work/oag
#RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*
#COPY --from=0 /images/Max_Oil_and_Gas_761.zip /work/oag/
#RUN unzip Max_Oil_and_Gas_761.zip && unzip oilandgas_7.6.1_launchpad.zip \
#  && /opt/IBM/InstallationManager/eclipse/tools/imcl install com.ibm.tivoli.tpae.IS.OilAndGas \
# -repositories /work/oag/OilAndGasInstallerRepository.zip \
# -installationDirectory /opt/IBM/SMP -acceptLicense && rm -rf /work/oag/*
#COPY --from=0 /images/OG7610_ifixes.20200316-0706.zip /work/oag/
#RUN unzip -o OG7610_ifixes.20200316-0706.zip -d /opt/IBM/SMP/maximo/ && rm -rf /work/oag/*


RUN /work/buildwars.sh
