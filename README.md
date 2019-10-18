# Building and deploying an IBM Maximo Asset Management V7.6.1 with Liberty image to Docker

**This is an experimental version. Please report issues if you have some difficulties.**

Maximo with Liberty on Docker enables to run Maximo Asset Management with WebSphere Liberty on Docker. The images are deployed fine-grained services instead of single instance. The following instructions describe how to set up IBM Maximo Asset Management V7.6 Docker images. This images consist of several components e.g. WebSphere Liberty, Db2, and Maximo installation program.

Before you start, please check the official guide in technotes first. [Maximo Asset Management 7.6.1 WebSphere Liberty Support](https://www-01.ibm.com/support/docview.wss?uid=swg22017219)

![Componets of Docker Images](https://raw.githubusercontent.com/nishi2go/maximo-liberty-docker/master/maximo-liberty-docker.svg?sanitize=true)

## Required packages

* IBM Installation Manager binaries from [Installation Manager 1.8 download documents](http://www-01.ibm.com/support/docview.wss?uid=swg24037640)

  IBM Enterprise Deployment (formerly known as IBM Installation Manager) binaries:
  * IED_V1.8.8_Wins_Linux_86.zip

* IBM Maximo Asset Management V7.6.1 binaries from [Passport Advantage](http://www-01.ibm.com/software/passportadvantage/pao_customer.html)

  IBM Maximo Asset Management V7.6.1 binaries:
  * MAM_7.6.1_LINUX64.tar.gz

  IBM WebSphere Liberty base license V9 binaries:
  * wlp-base-license.jar

  IBM Db2 Advanced Workgroup Edition V11.1 binaries:
  * DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz

* Feature Pack/Fix Pack binaries from [Fix Central](http://www-945.ibm.com/support/fixcentral/)

  IBM Maximo Asset Management V7.6.1 Feature pack 1 binaries:
  * MAMMTFP7611IMRepo.zip

  IBM Db2 Server V11.1 Fix Pack 4 Mod 1
  * v11.1.4fp4a_linuxx64_server_t.tar.gz

## Building IBM Maximo Asset Management V7.6.1 with Liberty image by using build tool

Prerequisites: all binaries must be accessible via a web server during building phase.

You can use a tool for building docker images by using the build tool.

Usage:
```
Usage: build.sh [OPTIONS]

-r | --remove           Remove images when an image exists in repository
-J | --disable-jms      Disable JMS configurations in application servers
-v | --verbose          Output verbosity in docker build
-h | --help             Show this help text
```

Procedures:
1. Clone this repository
    ```bash
    git clone https://github.com/nishi2go/maximo-liberty-docker.git
    ```
2. Place the downloaded Maximo, IBM Db2, IBM Installation Manager and IBM WebSphere Liberty License binaries into the maximo-liberty-docker/images directory.
    ```bash
    cd maximo-liberty-docker
    ls -l images
    check.sh                                 Dockerfile                    MAM_7.6.1_LINUX64.tar.gz  packages.list                         wlp-nd-license.jar
    DB2_AWSE_REST_Svr_11.1_Lnx_86-64.tar.gz  IED_V1.8.8_Wins_Linux_86.zip  MAMMTFP7611IMRepo.zip     v11.1.4fp4a_linuxx64_server_t.tar.gz
    ```
3. Run the build tool
   ```bash
   bash build.sh [-r] [-v] [-J]
   ```

   Example:
   ```bash
   bash build.sh -r
   ```
   Note 1: This script works on Windows Subsystem on Linux.<br>
   Note 2: md5sum is required. For Mac, install it manually - https://raamdev.com/2008/howto-install-md5sum-sha1sum-on-mac-os-x/
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

## Skip the maxinst process in starting up the maxdb container by using Db2 restore command

[Maxinst program](http://www-01.ibm.com/support/docview.wss?uid=swg21314938) supports to initialize and create a Maximo database that called during the "deployConfiguration" process in the Maximo installer. This process is painfully slow because it creates more than thousand tables from scratch. To skip the process, you can use a backup database to restore during first boot time in a maxdb service. So then, it can reduce the creation time for containers from second time.

Procedures:
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
    docker-compose exec maxdb /work/backup.sh maxdb76 /backup
    ```
    Note: Backup image must be only one in the directory. Backup task must fail when more than two images in it.

So that, now you can create the containers from the backup image that is stored in the directory.

## To do
1. Kubernetes
2. Password with Docker secrets
3. Industry Solutions
