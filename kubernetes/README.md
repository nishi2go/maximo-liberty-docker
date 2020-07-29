# Maximo on Kubernetes

The document describes how to deploy Maximo on Docker to a Kubernetes environment. Kubernetes is a highly popular multi-node Docker orchestration system that invented by Google. Maximo Asset Management has supported to deploy its application services with WebSphere Liberty into OpenShift Container Platform, a RedHat's proprietary Kubernetes distribution. IBM has officially published a [Maximo on OpenShift document](https://www.ibm.com/support/pages/deploying-and-running-ibm%C2%AE-maximo%C2%AE-asset-management-red-hat%C2%AE-openshift%C2%AE), but it has not described how to deploy Maximo to vanilla Kubernetes environments. Maximo on Docker provides Kubernetes YAML deployment files that have been created with plain Kubernetes dialects so that you can deploy Maximo into several Kubernetes environments such AKE, EKS, GKE, and on-premise Kubernetes. 

### How to deploy Maximo Docker to Kubernetes

1. Prepare a private Docker registry for clustered Kubernetes environment.

    Whatever deploying to a multi-node cluster or not, I recommend you to use a private Docker registry to distribute the images. By using Docker registry, you don't need to push your images into each Kubernetes node. Note that you cannot use a public registry like DockerHub with no credentials because the compiled images include proprietary software that you don't have rights to redistribution. 

    To set up your private registry, check the official documentation from the Kubernetes community for a private Docker registry in Kubernetes. 

    [Using a Private Registry](https://kubernetes.io/docs/concepts/containers/images/#using-a-private-registry)

    When you use a private registry, you need to change the names of images with registry's host name and port number in the YAML files. Kubernetes community issues official documentation for the naming rules of images in YAML files.

    [Image names](https://kubernetes.io/docs/concepts/containers/images/#image-names)

    Here is an example to use a private registry.
    
    ```yaml
    spec:
      containers:
      - env:
        ...
        image: registry.example.com:5000/maximo-liberty/maximo-ui:7.6.1.2
        imagePullPolicy: IfNotPresent
        name: maximo-ui
        ...
      imagePullSecrets:
      - name: your-secret
    ```


2. Build and push Maximo Docker images by using ``build.sh``.

    You can use the build tool in Maximo on Docker to build and push the images to a Docker registry. The build tool has an option to push built images to an external registry with ```--push-registry=REGISTRY_URL```. Each built image is automatically tagged and pushed to the external registry by using the option e.g. ```registry.example.com:5000/maximo-docker/maximo-ui:7.6.1.2``` from ```maximo-liberty/maximo-ui:7.6.1.2```.

    For example:
    ```bash
    ./build.sh -r -rt -p --push-registry=registry.example.com:5000
    ```

3. Create database and Liberty admin secrets.

    A database password and a Liberty admin credential are stored in [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/). You can change these passwords to edit the following YAML files.

    ```
    kubernetes/maximo-maxdb-credential.yaml
    kubernetes/liberty-admin-credential.yaml
    ```

    To apply the secrets, run the following commands. 

    ```bash
    kubectl apply -f kubernetes/maximo-maxdb-credential.yaml
    kubectl apply -f kubernetes/liberty-admin-credential.yaml
    ```

4. Select a database (Db2) deployment platform.

    The database container of Maximo on Docker does not support Db2 HADR (high-availability,disaster-recovery). The function is required to run it on Kubernetes multi-node cluster because the pods in Kubernetes will move to another container when OOM Killer is issued from the Kubernetes scheduler. For more details, see the official document [Configure Out of Resource Handling](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#node-oom-behavior). 

    Two options are available to deploy a database for the Kubernetes environment.

    4.1. (Testing purpose only) Deploy a sample Maximo database container.

    The ```maximo-maxdb-deployment.yaml``` enables to deploy a ```maxdb``` container to a Kubernetes environment. Note that the number of replicas must be 1 because it does not support HADR and a multi-node cluster. To deploy the container, run the command as follows:

    ```bash
    kubectl apply -f kubernetes/maximo-maxdb-deployment.yaml
    ```

    4.2. Deploy a Maximo schema to an external database service.

    Db2 high-availability configuration such as [portworx](https://www.ibm.com/cloud/blog/how-to-running-ha-ibm-db2-on-kubernetes), any DBaaS service, or on-premise servers for Db2 is required for production use. The Db2 external service must be registered in Kubernetes to discover the database endpoint from Maximo application containers. The external services enable to recognize a non-Kubernetes service as a Kubernetes service.

    To define the external service, edit the ```externalIPs``` section in ```kubernetes/maximo-maxdb-external-service-deployment.yaml```.
    ```yml
    spec:
      ports:
      - name: jdbc
        port: 50005
        targetPort: 50005
      externalIPs:
        - external.database.example.com
    ```

    To deploy the external service, run the following command.

    ```bash
    kubectl apply -f kubernetes/maximo-maxdb-external-service-deployment.yaml
    ```

    The Maximo schema must be installed to the prepared database instance. You can run the Maximo installer from Kubernetes job as follows:

    ```bash
    kubectl apply -f kubernetes/maximo-installation-job.yaml
    ```

5. Deploy required and optional Maximo resources.

    You can start to deploy Maximo containers to your Kubernetes environment. Maximo UI and Crontask clusters are the required services to run the Maximo. The other services, report, MEA, API, and JMS, are optional. To deploy the required services, run the following command.

    ```bash
    kubectl apply -f kubernetes/maximo-minimum-deployment.yaml
    ```

    To deploy the other components e.g. Maximo API service, run the following command.

    ```bash
    kubectl apply -f kubernetes/maximo-api-deployment.yaml
    ```

    Check the other optional services from the ```kubernetes``` directory.

6. Set up Ingress provider to expose Maximo resources externally.

    Ingress enables to expose your services to the outside of Kubernetes internals. Ingress allows to define the route the traffic with URL paths and load balancing the client requests with Kubernetes YAML definitions. There are several Ingress controllers in each cloud provider such as AWS, Azure, GCP and on-premise. Find the [Kubernetes Ingress document](https://kubernetes.io/docs/concepts/services-networking/ingress/)  that which any Ingress controller is supported in your cloud provider. Maximo on Kubernetes provides a general template ```kubernetes/maximo-ingress-deployment.yaml``` for customizing it for your cloud provider. You can edit and apply it with ``` kubectl ``` command to deploy the Ingress services. You must install Ingress controller before deploying a Maximo Ingress template.

    Note that the ingress service must enable *sticky session*. Please check the documents of your Ingress controller provider to enable the feature.

    For example, use the ```maximo-ingress-haproxy-deployment.yaml``` template when you use HAProxy ingress controller.

    ```bash
    kubectl apply -f kubernetes/maximo-ingress-haproxy-deployment.yaml
    ```

    For example, use the ```maximo-ingress-traefik-deployment.yaml``` template when you use Traefik ingress controller.

    ```bash
    kubectl apply -f kubernetes/maximo-ingress-traefik-deployment.yaml
    ```

