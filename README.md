# Building and deploying an IBM Maximo Asset Management V7.6.1 with Liberty image to Docker.

Maximo with Liberty on Docker enables to run Maximo Asset Management with WebSphere Liberty on Docker. The images are deployed fine-grained services instead of a single instance. The following instructions describe how to set up IBM Maximo Asset Management V7.6 Docker images. These images consist of several components e.g. WebSphere Liberty, Db2, and Maximo installation program.

Before you start, please check the official guide in technotes first. [Maximo Asset Management 7.6.1 WebSphere Liberty Support](https://www-01.ibm.com/support/docview.wss?uid=swg22017219)

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

  IBM Maximo Asset Management V7.6.1 Feature pack 1 binary:
  * MAMMTFP7611IMRepo.zip

  IBM Db2 Server V11.1 Fix Pack 4 Mod 1
  * v11.1.4fp4a_linuxx64_server_t.tar.gz

## Building IBM Maximo Asset Management V7.6.1 with Liberty image by using a build tool.

Prerequisites: all binaries must be accessible via a web server during a building phase.

You can use a tool for building docker images by using the build tool.

Usage:
```
Usage: build.sh [OPTIONS]

Build Maximo Docker containers.

-r | --remove           Remove images when an image exists in repository
-R | --remove-only      Remove images without building when an image exists in repository
-c | --use-custom-image Build a custom image for Maximo installation container
-v | --verbose          Output verbosity in docker build
-s | --skip-db          Skip to build and remove a DB image
-h | --help             Show this help textt
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
    MAMMTFP7611IMRepo.zip
    v11.1.4fp4a_linuxx64_server_t.tar.gz
    ```
3. Run the build tool
   ```bash
   bash build.sh [-r] [-v] [-J]
   ```

   Example:
   ```bash
   bash build.sh -r
   ```
   Note: This script works on Windows Subsystem on Linux.<br>
4. Edit docker-compose.yml to enable optional servers e.g. maximo-api, maximo-report and etc.
5. Run containers by using the Docker Compose file to create and deploy instances:
    ```bash
    docker-compose up -d
    ```
    Note: It will take 3-4 hours (depend on your machine) to complete the installation.

    You can scale servers with docker-compose --scale option.
    ```bash
    docker-compose up -d --scale maximo-ui=2
    ```
6. Make sure to be accessible to Maximo login page: http://hostname/maximo

## How to use a custom build image.

In order to install industry solutions e.g. Oil & Gas, Service Providers and etc, you can use a custom Maximo image in the ``` custom ``` directory. You can add the scripts to ``` custom/Dockerfile ```. There are Maximo for Oil & Gas sample scripts in the dockerfile. Please uncomment the section in the file to install the Maximo for Oil & Gas V7.6.1 onto Maximo Asset Management V7.6.1.1.

#### Sample steps to install Oil and Gas Industry Solution.

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
    build.sh -c
    ``` 

## Customize your environment.

In order to install a second language, deploy demo data or change default passwords, edit the ``` build.args ``` file before building the container images. The following parameters are available by default.

```properties
deploy_db_on_build=yes
mxintadm_password=changeit
maxadmin_password=changeit
maxreg_password=changeit
db_port=50005
db_maximo_password=changeit
base_lang=en
add_langs=de,fr
admin_email_address=root@localhost
smtp_server_host_name=localhost
skin=iot18
enable_demo_data=no
enable_jms=yes
```

## Database deployment on build vs. on runtime.

The database deployment a.k.a maxinst and updatedb will be executed on the docker build time by default. It reduces to the initial start-up time, but longer the build time. When you want to switch the behavior to deploy the database schema on runtime, run the following procedures before building the images.

##### Procedures to switch deploy db on runtime.

1. Uncomment the maximo section in ```docker-compose.yml```.
2. Change ```deploy_db_on_build``` to no in ```build.args```.
3. Run the build command.

## Skip the database deployment in build the maxdb container by using Db2 bakup image.

[Maxinst program](http://www-01.ibm.com/support/docview.wss?uid=swg21314938) supports to initialize and create a Maximo database that called during the "deployConfiguration" process in the Maximo installer. This process is painfully slow because it creates more than a thousand tables from scratch. To skip the process, you can use a backup database image to restore during the build time in a maxdb container image. 

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

## Restore the database in starting up the maxdb container by using Db2 backup image.

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
4. Uncomment the following volume configuration in docker-compose.yml.
    ```yaml
      maxdb:
        volumes:
          - type: bind
            source: ./backup
            target: /backup
    ```
5. Run containers by using the Docker Compose file. (follow above instructions)
6. Take a backup from the maxdb service by using a backup tool.
    ```bash
    docker-compose exec maxdb /work/db2/backup.sh maxdb76 /backup
    ```
    Note: Backup image must be only one in the directory. The backup task must fail when more than two images in it.

So that, now you can create the containers from the backup image that is stored in the directory.

## To do
1. Kubernetes (OpenShift)
2. Password with Docker secrets
