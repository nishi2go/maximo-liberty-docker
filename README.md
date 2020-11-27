# Docker images for IBM Maximo Asset Management V7.6.1 with Liberty.

Maximo with Liberty on Docker enables to run Maximo Asset Management with WebSphere Liberty on Docker. The images are deployed fine-grained services instead of a single instance. The following instructions describe how to set up IBM Maximo Asset Management V7.6 Docker images. These images consist of several components e.g. WebSphere Liberty, Db2, and Maximo installation program.

Before you start, learn more about Maximo WebSphere Liberty support from the official documentation. [Maximo Asset Management 7.6.1 WebSphere Liberty Support](https://www.ibm.com/support/pages/node/572105)

![Componets of Docker Images](https://raw.githubusercontent.com/nishi2go/maximo-liberty-docker/master/maximo-liberty-docker.svg?sanitize=true)

## Required packages.

* IBM Installation Manager binaries from [Installation Manager 1.8 download documents](http://www-01.ibm.com/support/docview.wss?uid=swg24037640)

  IBM Enterprise Deployment (formerly known as IBM Installation Manager) binaries:
  * IED_V1.8.8_Wins_Linux_86.zip

* IBM Maximo Asset Management V7.6.1 binaries from [Passport Advantage](http://www-01.ibm.com/software/passportadvantage/pao_customer.html)

  IBM Maximo Asset Management V7.6.1 binaries:
  * MAM_7.6.1_LINUX64.tar.gz

  IBM WebSphere Liberty Network Deployment license V9 binaries:
  * wlp-nd-license.jar

  IBM Db2 Advanced Workgroup Edition V11.1 binaries:
  * DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz

* Feature Pack/Fix Pack binaries from [Fix Central](http://www-945.ibm.com/support/fixcentral/)

  IBM Maximo Asset Management V7.6.1 Feature pack 2 binary:
  * MAMMTFP7612IMRepo.zip

  IBM Db2 Server V11.1 Fix Pack 5
  * v11.1.4fp5_linuxx64_server_t.tar.gz

## Building IBM Maximo Asset Management V7.6.1 with Liberty image by using a build tool.

You can use a tool for building docker images by using the build tool.

Usage:
```
Usage: build.sh [OPTIONS]

Build Maximo Docker containers.

-r  | --remove                 Remove images when an image exists in repository.
-R  | --remove-only            Remove images without building when an image exists in repository.
-rt | --remove-latest-tag      Do not add the "letest" tag to the built images.
-c  | --use-custom-image       Build a custom image for Maximo installation container.
-v  | --verbose                Show detailed output of the docker build.
-p  | --prune                  Remove intermediate multi-stage builds automatically.
-s  | --skip-db                Skip building and removing a DB image.
--deploy-db-on-runtime         Deploy the Maximo database on runtime.
--push-registry=REGISTRY_URL   Push the built images to a specified remote Docker registry.
--namespace=NAMESPACE          Specify the namespace of the Docker images (default: maximo-liberty).
-h  | --help                   Show this help text.
```

Procedures:
1. Clone this repository
    ```bash
    git clone https://github.com/nishi2go/maximo-liberty-docker.git
    ```
2. Place the downloaded Maximo, IBM Db2, IBM Installation Manager and IBM WebSphere Liberty License binaries into the maximo-liberty-docker/images directory.
    ```bash
    > cd maximo-liberty-docker
    > ls -l images
    check.sh
    Dockerfile
    MAM_7.6.1_LINUX64.tar.gz
    packages.list
    wlp-nd-license.jar
    DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz
    IED_V1.8.8_Wins_Linux_86.zip
    MAMMTFP7612IMRepo.zip
    v11.1.4fp5_linuxx64_server_t.tar.gz
    ```
3. Run the build tool
   ```bash
   bash build.sh [-r] [-v] [-c] [-rt] [-p]
   ```

   Example:
   ```bash
   bash build.sh -r -v -rt -p
   ```
   Note: This script works on Windows Subsystem on Linux.
4. Edit ```docker-compose.yml``` to enable optional services e.g. maximo-api, maximo-report and etc.
5. Run containers by using the Docker Compose file to create and deploy instances:
    ```bash
    docker-compose up -d
    ```
    To scale servers with the ```docker-compose --scale``` option:
    ```bash
    docker-compose up -d --scale maximo-ui=2
    ```
6. Make sure to be accessible to Maximo login page: http://hostname/maximo

## How to deploy Maximo on Kuberenetes

See the [Maximo on Kubernetes](https://github.com/nishi2go/maximo-liberty-docker/blob/master/kubernetes/README.md) document.

## How to use a custom build image.

To install industry solutions e.g. Oil & Gas, Service Providers and the other offerings, you can use a custom Maximo dockerfile which aims to extend the original Maximo installation container. A sample script ``` custom/Dockerfile ``` allows to run IBM Installation Manager, unzip Interim Fixes and/or etc at a build time. You can find a Maximo for Oil & Gas sample in the dockerfile. Please uncomment the section in the file to install the Maximo for Oil & Gas V7.6.1 onto Maximo Asset Management V7.6.1.2.

#### Sample steps to install Maximo for Oil and Gas Industry Solution.

1. Uncomment the installation section in ``` custom/Dockerfile ```.
    ```dockerfile
    RUN mkdir /work/oag
    WORKDIR /work/oag
    RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*
    COPY --from=0 /images/Max_Oil_and_Gas_761.zip /work/oag/
    RUN unzip Max_Oil_and_Gas_761.zip && unzip oilandgas_7.6.1_launchpad.zip \
      && /opt/IBM/InstallationManager/eclipse/tools/imcl install com.ibm.tivoli.tpae.IS.OilAndGas \
    -repositories /work/oag/OilAndGasInstallerRepository.zip \
    -installationDirectory /opt/IBM/SMP -acceptLicense && rm -rf /work/oag/*
    COPY --from=0 /images/OG7610_ifixes.20200316-0706.zip /work/oag/
    RUN unzip -o OG7610_ifixes.20200316-0706.zip -d /opt/IBM/SMP/maximo/ && rm -rf /work/oag/*
    ```
2. Put the installation image, e.g. ```Max_Oil_and_Gas_761.zip``` and ```OG7610_ifixes.20200316-0706.zip```, to the ``` images``` directory.
3. Run the build command with ``-c`` or ```--use-custom-image```.
    ```bash
    build.sh -c -p -rt
    ``` 

## Customize your environment.

In order to install a second language, deploy demo data or change default passwords, edit the ``` build.args ``` and ``` .env ``` file before building the container images. The following parameters are available by default.

```build.args```
```properties
# Deploy DB schema on build.
deploy_db_on_build=yes
# Enable and build the JMS services.
enable_jms=yes
# Update Installation Manager to the latest level.
update_im=no
```

```.env```
```properties
# Default passwords
ENV_DB_MAXIMO_PASSWORD=changeit
ENV_MXINTADM_PASSWORD=changeit
ENV_MAXADMIN_PASSWORD=changeit
ENV_MAXREG_PASSWORD=changeit
# Liberty admin user
ENV_ADMIN_USER_NAME=admin 
ENV_ADMIN_PASSWORD=changeit
# Language installation
ENV_BASE_LANG=en
ENV_ADD_LANGS=de,fr,ja
# Default e-mail configurations
ENV_ADMIN_EMAIL_ADDRESS=root@localhost
ENV_SMTP_SERVER_HOST_NAME=localhost
# Skin
ENV_SKIN=iot18
# Install the demo data
ENV_ENABLE_DEMO_DATA=no
```

## Database deployment on build vs. on runtime.

The database deployment a.k.a maxinst and updatedb will be executed on the docker build time by default. It reduces to the initial start-up time, but longer the build time. When you want to switch the behavior to deploy the database schema on runtime, run the following procedures before building the images.

#### Procedures to switch deploy database schemas on runtime.

1. Uncomment the all ```volumes``` sections in ```docker-compose.yml```.
2. Uncomment the maximo section in ```docker-compose.yml```.
3. Run the build command with ```--deploy-db-on-runtime``` or change ```deploy_db_on_build``` to ```no``` in ```build.args``` then run the build.sh command.

   Example:
   ```bash
   bash build.sh -r -v -rt -p --deploy-db-on-runtime
   ```
4. Change the values of ```ENV_GEN_MAXIMO_PROPERTIES``` to ```no``` in ```.env``` 

## Skip the database deployment during the maxdb container building time by using a Db2 backup image.

[Maxinst program](http://www-01.ibm.com/support/docview.wss?uid=swg21314938) supports to initialize and create a Maximo database that is called during the "deployConfiguration" process in the Maximo installer. This process is painfully slow because it creates more than a thousand tables from scratch. To skip the process, you can use a backup database image to restore during the build time in a maxdb container image. 

#### Procedures:

1. Move to the cloned directory.
    ```bash
    cd maximo-liberty-docker
    ```
2. Make a backup directory.
    ```bash
    mkdir ./images/backup
    ```
3. Place your backup image to the above directory.
4. Build container images by using the build tool.

## Building IBM Maximo Asset Management V7.6 images with an Oracle Database Container by using build tool

Oracle database containers are officially provided by Oracle from the [repository](https://github.com/oracle/docker-images/tree/master/OracleDatabase). You can run the Maximo on Docker on top of Oracle Container. Currently, the supported installation process is [database deployment on runtime](https://github.com/oracle/docker-images/tree/master/OracleDatabase) only.

### Prerequisites:
- An Oracle Database containar or any on-premise instance must be prepared before running ```docker-compose``` command.

1. Follow the guide from the [repo](https://github.com/oracle/docker-images/tree/master/OracleDatabase) to create an Oracle Database container.
2. Clone this repository
    ```bash
    git clone https://github.com/nishi2go/maximo-liberty-docker.git
    ```
3. Place the downloaded Maximo, IBM Db2, IBM Installation Manager and IBM WebSphere Liberty License binaries into the maximo-liberty-docker/images directory.
    ```bash
    > cd maximo-liberty-docker
    > ls -l images
    check.sh
    Dockerfile
    MAM_7.6.1_LINUX64.tar.gz
    packages.list
    wlp-nd-license.jar
    DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz
    IED_V1.8.8_Wins_Linux_86.zip
    MAMMTFP7612IMRepo.zip
    v11.1.4fp5_linuxx64_server_t.tar.gz
    ```
4. Run the build tool
   Example:
   ```bash
   bash build.sh -r -v -c -rt --skip-db
   ```
   Note: This script works on Windows Subsystem on Linux.
5. Uncomment the all ```volumes``` sections in ```docker-compose.ora.yml```.
6. Edit ```docker-compose.ora.yml``` to enable optional servers e.g. maximo-api, maximo-report and etc.
7. Run the Oracle container by using the Docker Compose file to create and deploy the database instance first:
    ```bash
    docker-compose -f docker-compose.ora.yml -d maxdb
    ```

    Wait until the text "```DATABASE IS READY TO USE!```" is shown in the logs. 
    ```bash
    docker-compose -f docker-compose.ora.yml logs -f maxdb
    ```
8. Run the Maximo container to deploy the database schema to Oracle database. 
    ```bash
    docker-compose -f docker-compose.ora.yml -d maximo
    ```

    Wait until the text "```CTGIN5012I: The reconfiguration action updateApplicationDBLite completed successfully.```" is shown in the logs. 
    ```bash
    docker-compose -f docker-compose.ora.yml logs -f maximo
    ```
   Note: It will take 3-4 hours (depend on your machine) to complete the installation.
9. Run the all other containers:
    ```bash
    docker-compose -f docker-compose.ora.yml up -d
    ```
    To scale servers with the ```docker-compose --scale``` option.
    ```bash
    docker-compose -f docker-compose.ora.yml up -d --scale maximo-ui=2
    ``` 
10. Make sure to be accessible to Maximo login page: http://hostname/maximo

## Restore the database during starting up the maxdb container by using a Db2 backup image.

When you want to restore your database backup image on runtime, run the following procedures.

#### Procedures:

1. Build container images first (follow above instructions)
2. Move to the cloned directory.
    ```bash
    cd maximo-liberty-docker
    ```
3. Make a backup directory.
    ```bash
    mkdir ./backup
    ```
4. Uncomment the following volume configuration in ```docker-compose.yml.```
    ```yaml
      maxdb:
        volumes:
          - type: bind
            source: ./backup
            target: /backup
    ```
5. Run containers by using the Docker Compose file. (follow the above instructions)

#### Take a backup database from a running container.

You can take a backup from the ```maxdb``` container by using a backup tool.
```bash
docker-compose exec maxdb /work/db2/backup.sh maxdb76 /backup
```

Note: There must be one file in the directory. The restore task will fail when more than two images in it.

## To do
1. Helm support
2. Industry Solution templates