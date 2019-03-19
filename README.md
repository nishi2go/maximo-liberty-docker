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

  IBM Db2 Server V11.1 Fix Pack 3
  * v11.1.3fp3_linuxx64_server_t.tar.gz

## Building IBM Maximo Asset Management V7.6.1 with Liberty image by using build tool

Prerequisites: all binaries must be accessible via a web server during building phase.

You can use a tool for building docker images by using the build tool.

Usage:
```
Usage: build.sh [OPTIONS] [DIR]

-c | --check            Check required packages
-C | --deepcheck        Check and compare checksum of required packages
-r | --remove           Remove images when an image exists in repository
-J | --disable-jms      Disable JMS configurations in application servers
-d | --check-dir [DIR]  The directory for validating packages (Docker for Windows only)
-v | --verbose          Output verbosity in docker build
-h | --help             Show this help text
```

Procedures:
1. Place the downloaded Maximo, IBM Db2, IBM Installation Manager and IBM WebSphere Liberty License binaries on a directory
2. Clone this repository
    ```bash
    git clone https://github.com/nishi2go/maximo-docker.git
    ```
3. Move to the directory
    ```bash
    cd maximo-docker
    ```
4. Run build tool
   ```bash
   bash build.sh [-c] [-C] [-r] [Image directory]
   ```

   Example:
   ```bash
   bash build.sh -c -r /images
   ```

   Example for Docker for Windows:
   ```bash
   bash build.sh -c -r -d /images "C:/images"
   ```
   Note 1: This script works on Windows Subsystem on Linux.<br>
   Note 2: md5sum is required. For Mac, install it manually - https://raamdev.com/2008/howto-install-md5sum-sha1sum-on-mac-os-x/
7. Edit docker-compose.yml to enable optional servers e.g. maximo-api, maximo-report and etc.
6. Run containers by using the Docker Compose file to create and deploy instances:
    ```bash
    docker-compose up -d
    ```
    Note: It will take 3-4 hours (depend on your machine) to complete the installation.

    You can scale servers with docker-compose --scale option.
    ```bash
    docker-compose up -d --scale maximo-ui=2
    ```
7. Make sure to be accessible to Maximo login page: http://hostname/maximo

## Skip the maxinst process in starting up the maxdb container by using Db2 restore command

[Maxinst program](http://www-01.ibm.com/support/docview.wss?uid=swg21314938) supports to initialize and create a Maximo database that called during the "deployConfiguration" process in the Maximo installer. This process is painfully slow because it creates more than thousand tables from scratch. To skip the process, you can use a backup database to restore during first boot time in a maxdb service. So then, it can reduce the creation time for containers from second time.

Procedures:
1. Build container images first (follow above instructions)
2. Move to the cloned directory.
    ```bash
    cd maximo-docker
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
    docker-compose exec maximo-docker-liberty_maxdb_1 /work/backup.sh maxdb76 /backup
    ```
    Note: Backup image must be only one in the directory. Backup task must fail when more than two images in it.

So that, now you can create the containers from the backup image that is stored in the directory.

## To do
1. Optionalize JMS configurations
2. Kubernetes
