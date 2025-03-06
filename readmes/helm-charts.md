# Helm Chart for EKS

This README files explains the Helm chart used to deploy the sample application on an EKS cluster. The Helm chart is stored in the **helm-charts** folder inside the **devops-app** repository.

## Overview

The Helm chart is a **custom chart** designed for deploying the sample application`(i.e., taxi booking app)`. It simplifies application deployment on EKS by templating Kubernetes manifests such as **Deployments, Services, Namespaces,** and **Secrets**.

## Repository Structure

```
helm-charts/
├── templates/              # Contains Kubernetes manifest files
│   ├── deployments.yaml    # Defines the application deployment
│   ├── namespace.yaml      # Defines the namespace
│   ├── secrets.yaml        # Stores image pull secrets
│   ├── service.yaml        # Defines the service configuration
├── Charts/                 # (Empty) Used for Helm dependencies (ignored by .helmignore)
├── .helmignore             # Lists files to ignore during Helm packaging
├── Chart.yaml              # Metadata about the Helm chart
├── values.yaml             # Default values passed to Kubernetes manifests
└── monitoring-values.yaml  # Overrides for Prometheus and Grafana service types
```

### Key Files Explained

#### 1. `templates/` Folder 
- Contains all the Kubernetes manifest files used to deploy and configure the application.These templates use Helm placeholders (`{{ .Values }}`) to dynamically set values at deployment.
    - **`deployments.yaml`**: Defines the Deployment resource for the sample application, specifying the number of replicas, container image details, container specifications, environment variables, and ports.
    - **`namespace.yaml`**: Defines the dedicated namespace for the application to ensure isolation within the cluster.
    - **`secrets.yaml`**: Stores sensitive information, such as Docker registry credentials, for pulling private container images.
    - **`service.yaml`**: Defines the Kubernetes Service to expose the application internally or externally, supporting different service types (ClusterIP, LoadBalancer, NodePort) based on Helm values.

#### 2. `Chart.yaml`
- This file provides metadata about the Helm chart, such as its name, description, version, and application version.

    #### `sample Chart.yaml`
    ```yaml
    apiVersion: v2
    name: taxi-booking
    description: A Helm chart for deploying the Taxi Booking application
    type: application
    version: 0.1.0
    appVersion: "1.0.1"
    ```

#### 3. `values.yaml`
- This file contains configurable values for the Helm chart, such as:
    - **Replica count**: Number of application instances.
    - **Image repository and tag**: Defines the container image details.
    - **Image Pull Secrets**: Docker credentials to pull the image from DockerHub.
    - **Service type and ports**: Configures how the service is exposed.
    - **Namespace**: Specifies the deployment namespace.

    #### `sample values.yaml`
    ```yaml
    replicaCount: 2

    image:
    repository: <yourdockerusername>/<image-name> # (e.g.,taxi-app)
    tag: "1.0.1"
    pullPolicy: Always

    imagePullSecrets:
    name: docker-config-creds
    dockerconfigjson: "" # leave this empty value will be injected from jenkins pipeline

    service:
    type: LoadBalancer
    port: 8001
    targetPort: 8080

    namespace: <your namespace> # (e.g.,taxi-app)
    ```


#### 4. `monitoring-values.yaml`
- This file is used to override default values for Prometheus and Grafana services. It sets the service type to LoadBalancer, allowing external access to monitoring tools.

## Creating Your Own Helm Chart

To create a Helm chart from scratch, use the following command:

```bash
helm create <custom-chart-name>
```
This generates a default chart structure that can be customized as per your needs. 
- Navigate to the `templates` folder and update with your manifest files.
- Update the **default values** in `values.yaml` based on your use case.
- Modify `Chart.yaml` to include **metadata** about the chart.

To push your Helm chart to a Git repository, simply add and commit the files:

```bash
git add helm-charts/
git commit -m "Adding custom Helm chart"
git push origin main
```

## Conclusion

Explore the **helm-charts** folder in the **devops-app** repository to understand how this Helm chart works. It simplifies EKS deployments by automating Kubernetes resource creation and configuration.

By following this guide, you can create, customize, and manage Helm charts for your own applications efficiently.
