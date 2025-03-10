# DevOps End to End Automation - Infra & Application

## Introduction  

This project serves as a **step-by-step guide** for learning and implementing **DevOps practices** in real-world scenarios. It covers **Infrastructure Automation, CI/CD pipeline setup, and Application Deployment**.  

This project uses **two repositories** to separate infrastructure and application deployment.

1. **devops-infra repo** - This repository manages AWS infrastructure provisioning, including **EC2** and **EKS**, using **Terraform**.
2. **devops-app repo** - This repository contains a sample application`(i.e., taxi booking app)`, a **Jenkinsfile** for the CI/CD pipeline, a **Dockerfile** for image creation, installation **shell scripts**, and **Helm charts**.

By following this guide, you will gain hands-on experience with **AWS, Terraform, Git, Jenkins, SonarCloud, JFrog, Docker, Kubernetes using Helm, Prometheus, and Grafana**. You will learn how to automate and manage cloud infrastructure while effectively deploying applications on Kubernetes.

## Prerequisites  

Before starting this project, ensure you have the following installed and configured:

### **1. System Requirements**  
- A system with **Windows, macOS, or Linux**.
- Minimum **8GB RAM**.
- **Stable internet connection**.

### **2. Required Software & Tools**  
- **Git Bash** – [Download & Install](https://git-scm.com/downloads)
- **AWS CLI** – [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- **Terraform** – [Download & Install](https://developer.hashicorp.com/terraform/downloads)
- **VSCode** - [Download & Install](https://code.visualstudio.com/download)

### **3. Cloud Requirements**
- An **AWS account** with a dedicated **IAM user** having permissions for **EC2, EKS, S3, and IAM roles & policies**. *(Note: Avoid using the root account credentials)*
- Either use the **default VPC** or create a **custom VPC** with **public internet access**.
- Create a **security group** with **SSH, HTTP, and HTTPS** access.
- If using **EC2 Instance Connect**, open **SSH** to the **EC2 Instance Connect address**. Otherwise, if using **Git Bash**, open **SSH** to your **home network's IP address**.
- Create an **S3** bucket to store the Terraform State file.
- Create an **EC2** Instance **Key Pair**, name it `devops-master-key.pem`.

### **4. Additional Setup**
- Configure `IAM user credentials` *(created above)* on the local machine using (`aws configure`).

    *Note: Avoid/exclude Root credentials usage.*
- Create a new or use an existing **GitHub account**.

## Architectural Diagram
- *Working on the Architectural Diagram will be added soon..*

## Infrastructure Setup

### **Infrastructure Overview**  
This project sets up a **Jenkins Master-Slave architecture** using **Ansible** and **Terraform**. The infrastructure provisions **three EC2 instances** with the following roles:

- **Ansible Control Node**: Manages the installation and configuration of **Jenkins Master** and **Jenkins Slave** using an inventory file.
- **Jenkins Master Node**: Installs **Java and Jenkins**, starts Jenkins, and enables it on boot.
- **Jenkins Slave Node**: Installs **Java, Maven, AWS CLI, Docker, Kubectl, and Helm**, configures Docker to start on boot, and connects to the **Jenkins Master** for CI/CD execution.

Follow these steps to provision AWS infrastructure using Terraform.

### **1. Clone the Infrastructure Repository**  
```sh
git clone https://github.com/saishandilya/devops-infra.git
cd devops-infra
```

Refer to the [**Infrastructure Guide**](readmes/infrastructure-terraform.md) file for a detailed overview of the infrastructure setup and the resources provisioned by this repository.

### **2. Defining Terraform Variables for EC2**
- Navigate to the **main.tf** file and review the configurations.
- Navigate to **backend.tf** file and update `bucket` and `region` values with your S3 bucket name and region.
- Create a **ec2.tfvars** file to define the necessary variables.

    #### `ec2.tfvars`  

    ```hcl
    ansible_instance_type   = "t2.micro"
    jenkins_instance_type   = "t2.medium"
    instance_key_name       = "devops-master-key"
    security_group_id       = "sg-xxxxxxxxxxxxx"
    public_subnet_id_list   = ["subnet-xxxxxxxxxx"]
    ```

**Note:** Place your **EC2 Key Pair** in `modules/ec2/files/` and the `ec2.tfvars` file in the **main project** folder. These files are excluded in `.gitignore`, so they will not be pushed to GitHub.

The **devops-master-key.pem** file is required to establish a **secure SSH connection** between the Ansible Control Node and Jenkins Master-Slave Nodes.

### **3. Initialize and Apply Terraform** 

Run the following commands to initialize Terraform and deploy the infrastructure:

```hcl
terraform init -backend-config="key=ec2/terraform.tfstate"
terraform validate
terraform plan -target="module.ec2" -var-file="ec2.tfvars" -out=ec2plan
terraform apply "ec2plan"
```

### **4. Jenkins Portal Setup**  

1. Open Jenkins in your browser: `http://<jenkins-master-public-ip>:8080` and Enter the **Administrator password** when prompted.
2. Log in to the Jenkins master node and retrieve the `initialAdminPassword` using the below command:
    ```sh
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```
    Copy and paste the password into the Jenkins portal.
3. Jenkins will prompt to either `Install Suggested Plugins` or `Select Plugins Manually`. Choose **Install Suggested Plugins** for a standard setup.

4. **Create Admin User**  
   - Provide the following details:  
     - **Username**  
     - **Password**  
     - **Full Name**  
     - **Email Address**  
   - Click **Save and Continue**.  

5. Set the Jenkins URL to default (e.g., `http://<jenkins-master-public-ip>:8080`). If using a domain-based setup, update it accordingly (e.g., `http://jenkins.example.com`). Click **Save and Finish**.

6. Jenkins setup is now complete! Click **Start using Jenkins** to access the dashboard.


### **5. Configure Jenkins Master-Slave Setup**

1. **Add SSH Credentials:** 
    - Go to **Manage Jenkins → Credentials**, select **Global**, and click **Add Credentials**.
    - Select **Kind**: **SSH Username with Private Key** and provide the following details:
        - **ID**: `master-slave`  
        - **Description**: SSH PEM key to access the Slave Node from the Master Node.
        - **Username**: `ubuntu`
        - **Private Key**:
            - Select **Enter Directly**, then click `add`
            - Copy and paste the contents of `<ec2-instance.pem>` key
        - **Passphrase**: (optional) Leave empty
        - Click **Create**.

2. **Add and Configure Slave Node:**
    - Navigate to **Manage Jenkins → Nodes** and click on **New Node**.
    - Enter a **Node Name** (e.g., `slave-node`), for **Type** select `Permanent Agent`, and click **Create**.  
    - Configure the new node with the following settings:  
        - **Description**: (Optional)  Slave node to build artifacts , docker image and application deployment on k8s using helm charts.
        - **Number of Executors**: `2`  
        - **Remote Root Directory**: `/home/ubuntu/jenkins`  
        - **Label**: `slave`  
        - **Usage**: Select `Only build jobs with label expressions matching this node`
        - **Launch Method**: Select `Launch agents via SSH`
            - **Host**: `<jenkins-slave-private-ip>`  
            - **Credentials**: Select `ubuntu` (created in step 1)  
            - **Host Key Verification Strategy**: `Non-verifying Verification Strategy`
        - **Availability**: `Keep this node online as much as possible`
    - Click **Save** to complete the setup.  

### **6. Install Plugins**
- Navigate to **Manage Jenkins → Plugins → Available Plugins**. 
- Search and select the following plugins:  
   - **Artifactory**  
   - **Pipeline: Stage View**  
   - **Docker Pipeline**  
   - **Terraform**  
- Click **Install** to begin the installation.

### **7. Deploy EKS** (Optional)
- This is an optional setup. You can perform it either as part of the infrastructure setup or during the application deployment stages, before the **`Cluster Validation`** stage.
- If you are setting up an EKS cluster for the first time, refer to the [**EKS Cluster Setup Guide**](readmes/eks-cluster-setup.md) for detailed instructions.

*Note: If you have been working on the project for more than a day, clean up the resources to avoid billing. You can recreate the cluster as part of the **application deployment** stages, before the `Cluster Validation` stage.*
## Application Setup

### **1. Clone the Application Repository**
- **Clone & push or Fork** the Application repository to your GitHub account to set up your local development environment.
    ```sh
    git clone https://github.com/saishandilya/devops-app.git
    ```

### **2. Jenkins Pipeline Configuration**
- Log in to **GitHub**, go to **User Profile → Settings → Developer Settings → Personal Access Tokens → Tokens (Classic)**, click **Generate New Token (Classic)**, enter your password, provide a **Note Name** (e.g., `Jenkins Access Token`), select the **necessary scope permissions** (or select all checkboxes), and click **Generate Token**.
- **Add GitHub Credentials:** 
    - Go to **Manage Jenkins → Credentials**, select **Global**, and click **Add Credentials**.
    - Select **Kind**: **Username with password** and provide the following details:
        - **Username**: `<provide your git-hub username>`. 
        - **Password**: Copy & Paste generated `GitHub Personal Access Token`. 
        - **ID**: `git-token`  
        - **Description**: Git Personal Access Token.
    - Click **Create**.
- Go to the **Jenkins Dashboard**, click **New Item**, enter the **Item Name** (e.g., `taxi-booking-app`), select **Item Type** as **Pipeline** and click **OK**.
- In the **Configure**, select the **General**, provide a **Description** (e.g., `Jenkins pipeline to deploy taxi booking application on k8s using helm.`), enable **Discard Old Builds**, set **Days to Keep Builds** (e.g., `7`), and **Max # of Builds to Keep** (e.g., `5`).
- In the **Pipeline** section, set **Definition** to `Pipeline Script` and inside **Script** select `Hello World` from the dropdown.
- Click **Apply & Save**.

### **3. Creating Pipeline Stages**
1. **Checkout Stage:** 
    - In the **Pipeline** section of the Job, click **Pipeline Syntax**, search for **Git**, enter the **Repository URL** (`<your github repo url from Step 1>`), select **Branch** as `main`, set **Credentials** to `None`, generate the **Pipeline Script**, copy the generated code, and replace it in the **checkout stage**.
    - Adding a `parameter` section to choose between **'deploy'** for application deployment and **'uninstall'** for removing application using Helm charts.
        ```groovy
        parameters {
            choice(name: 'ACTION', choices: ['deploy', 'uninstall'], description: 'Choose deploy or uninstall')
        }
        ```
    - Copy the below code and replace the HelloWorld Code: 
        ```groovy
        pipeline {
            agent { node { label 'slave' } }

            parameters {
                choice(name: 'ACTION', choices: ['deploy', 'uninstall'], description: 'Choose deploy or uninstall')
            }

            environment {
                GIT_COMMIT = ""
            }

            stages {
                stage('Checkout') {
                    steps {
                        echo 'Fetching application code from GitHub'
                        git branch: 'main', url: '<your github repo url>'
                        script {
                            GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                            echo "Current Git Commit ID: ${GIT_COMMIT}"
                        }
                    }
                }
            }
        }
        ```

2. **Compile & Build Stage** 
   - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage compiles the application code and builds the **JAR** or **WAR** file.
   - Add the **Maven** path to the **environment** variables in the Pipeline.
        ```groovy
        environment {
            PATH="/opt/apache-maven-3.9.6/bin:$PATH"
        }
        ```
        #### `Compile & Build Stage`
        ```groovy
        stage('Compile & Build') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                echo 'Compiling and Building the application code using Apache Maven'
                sh 'mvn compile && mvn clean package'
            }
        }
        ```
3. **Generate Test Reports Stage**
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **generates test report** for the **application code using Maven Surefire plugin**.
        #### `Generate Test Report Stage`
        ```groovy
        stage('Generate Test Report') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                echo "Generating test reports for the application code using Maven Surefire plugin"
                sh 'mvn test surefire-report:report'
            }
        }
        ```
4. **Code Quality Analysis**
    - Log in to [SonarCloud](https://www.sonarsource.com/products/sonarcloud/signup/) using your GitHub account.
    - **Create an Organization** 
        - Click the **‘+’** symbol on the top right and select **Create a new organization**.  
        - Choose **Create one manually**. In the **Enter your organization details** section, provide the **Organization Name** and **Organization Key**.  
        - In **Choose a plan** section, select the **Free Tier** and click **Create Organization**.  
    - **Create a New Project**  
        - In the newly created organization, click **Analyze New Project**.  
        - Provide a **Display Name** (the **Project Key** will be generated automatically as `org_name_display_name`).  
        - Set **Project Visibility** to **Public**.  
        - Choose **Set up project for Clean as You Code** as **Previous Version**, and click **Create Project**.
    - **Set Up Analysis Method**  
        - Select **Manually** as the **Analysis Method**.  
        - Choose **Maven** as the analysis tool.  
        - Copy & Save the generated **SONAR_TOKEN** and its **Value**.
    - **Configure Jenkins with SonarCloud Credentials**  
        - Go to **Manage Jenkins → Credentials**, select **Global**, and click **Add Credentials**.
        - Select **Kind**: **Secret Text** and provide the following details:
            - **Secret**: Copy & Paste generated `Sonar Token value`. 
            - **ID**: `sonar-token`  
            - **Description**: Sonar Access Token.
        - Click **Create**.
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Code Quality Analysis** performs static code quality analysis against **Security, Reliability, Maintainability, Hotspots Reviewed, Coverage and Duplications**.
   - Add the **SONAR_ORG, SONAR_PROJECT_KEY, SONAR_TOKEN** to the **environment** variables in the Pipeline.
        ```groovy
        environment {
            SONAR_TOKEN=credentials('sonar-token')
            SONAR_PROJECT_KEY=<your sonar project key>
            SONAR_ORG=<your sonar organisation name>
        }
        ```
        #### `Code Quality Analysis Stage`
        ```groovy
        stage('Code Quality Analysis') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                echo "Performing Static Code Quality Analysis"
                sh  """
                    mvn sonar:sonar \
                        -Dsonar.organization=${SONAR_ORG} \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.token=${SONAR_TOKEN}
                    """
            }
        }
        ```

5. **Quality Gate Check**(optional)
    - **Create a Quality Gate**
        - In the created **Organization**, navigate to **Quality Gates**, click on **Create**, provide a **Name** `(e.g., Bugs QG)`, and click **Save**. 
    - **Add Conditions to the Quality Gate**
        - Open the newly created **Quality Gate** and click **Add Conditions**.  
        - Set the following values:  
            - **Where**: Select **Overall Code**.  
            - **Search for Metrics**: Select **Bugs**.  
            - **Threshold Value**: Set to **150**.  
        - Click **Add Condition**.
    - **Set the Quality Gate as Default**  
        - Click on the **three dots** in the top-right corner of the created **Quality Gate**, from the dropdown, select **Set as Default**.
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Quality Gate Check** verifies the specified condition and determines whether the quality gate has passed or failed based on the provided metrics.
        #### `Quality Gate Check Stage`
        - This stage installs **jq** and calls the `checkSonarCloudQualityGate` function, storing the response in `status`. If the response is **ERROR**, the Quality Gate fails; otherwise, the Quality Gate passes.
        ```groovy
        stage('Quality Gate Check') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                echo "Validating code quality against Bugs Quality gate metrics"
                script {
                    timeout(time: 5, unit: 'MINUTES') { // Wait for SonarCloud processing
                        sh 'sudo apt-get install -y jq || sudo yum install -y jq'
                        def status = checkSonarCloudQualityGate()
                        if (status == "ERROR") {
                            error "Quality Gate failed. Bugs exceed the threshold!"
                        } else {
                            echo "Quality Gate passed."
                        }
                    }
                }
            }
        }
        ```
        #### `checkSonarCloudQualityGate`
        - The `checkSonarCloudQualityGate()` function verifies if a project's code quality meets the defined **Quality Gate** conditions in **SonarCloud**. It makes an **API request** using `curl` and retrieves the **Quality Gate status**, which returns **"OK"**(Pass) or **"ERROR"**(Fail). This Status is passed to `Quality Gate Check` Stage.
        ```groovy
        def checkSonarCloudQualityGate() {
            def response = sh(
                script: """
                    curl -s -u ${SONAR_TOKEN}: \
                    "https://sonarcloud.io/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}" \
                    | jq -r '.projectStatus.status'
                """,
                returnStdout: true
            ).trim()

            return response  // "OK" if passed, "ERROR" if failed
        }
        ```

6. **Publish Artifacts To Jfrog**
    - **Sign Up for JFrog Free Trial**  
        - Go to [JFrog Free Trial](https://jfrog.com/start-free/#trialOptions) and select the **14-day free trial** option, then sign up using **Google**.
        - Provide your last name, edit the **hostname**, choose your **hosting preferences** select your **working region**, and then click **Confirm and Start Trial**.  
        - Your **JFrog Trial Environment** will be created. Now, **Re-login** using Google after setup.
    - **Create a Maven Repository**  
        - Click User Profile in the top-right corner and select **Quick Repository Creation**, now choose **Maven**, click **Next**, provide a **repository prefix** (e.g., `taxi`), and click **Create** to generate repositories.
    - **Generate an Access Token**  
        - Navigate to **Administrator → User Management → Access Tokens**. Click **Generate Token** and choose **Scoped Token**, and provide a **description** (e.g., `jfrog access token`). Set **Token Scope** to `admin`, enter your **username** (e.g., your name or email ID), and set **Expiration Time** to **30 days**.  
        - Click **Generate**, then **copy and save** the token securely.
    - **Add Jfrog Credentials:** 
        - Go to **Manage Jenkins → Credentials**, select **Global**, and click **Add Credentials**.
        - Select **Kind**: **Username with password** and provide the following details:
            - **Username**: `<username provided while creating jfrog token>`
            - **Password**: `<copy paste generated token>`
            - **ID**: `jfrog-token`  
            - **Description**: Jfrog Access token.
        - Click **Create**.  
    -   Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Publish Artifacts To Jfrog** performs publishing generated **Artifacts to JFrog repository**.
        #### `Publish Artifacts To Jfrog Stage`
        - This stage connects to JFrog Artifactory server using Jenkins Artifactory Plugin, Upload specification, JAR file, and publish build information to JFrog Artifactory.
        #### `Add Registry`
        ```groovy
        def registry='<your jfrog-registry url>' (e.g., https://taxibooking.jfrog.io/)
        ```
        #### 
        ```groovy
        stage('Publish Artifacts To Jfrog') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                echo "Publishing Artifacts to JFrog repository"
                script {
                    // 1️⃣ Connect to JFrog Artifactory server using Jenkins Artifactory Plugin
                    def server = Artifactory.newServer(
                        url: registry + "/artifactory", 
                        credentialsId: "jfrog-token"
                    )
                    
                    // 2️⃣ Define metadata properties for tracking builds
                    def properties = "buildid=${env.BUILD_ID},commitid=${GIT_COMMIT}"
                    
                    echo "Workspace Path: ${env.WORKSPACE}"

                    // 3️⃣ Upload specification (Fixed file pattern issue)
                    def uploadSpec = """{
                        "files": [
                            {
                                "pattern": "${env.WORKSPACE}/<jenkins pipeline name>/target/(*)",
                                "target": "<repository prefix name>-libs-release-local/{1}",
                                "flat": "true",
                                "props": "${properties}"
                            }
                        ]
                    }"""

                    // 4️⃣ Upload JAR file using Artifactory plugin
                    def buildInfo = server.upload(uploadSpec)
        
                    // 5️⃣ Collect build environment details
                    buildInfo.env.collect()
        
                    // 6️⃣ Publish build information to JFrog Artifactory
                    server.publishBuildInfo(buildInfo)
                }
            }
        }
        ```

7. **Docker Image Creation**
    - Create a `Dockerfile` or use the `existing Dockerfile` from the your application repository.
    
        *Note: If you create a Dockerfile push it to your application repository.*

        #### `Dockerfile`
        ```Dockerfile
        FROM tomcat:9  

        # Use LABEL to specify metadata
        LABEL maintainer="devops@yourcompany.com"

        # Copy the WAR file to the Tomcat webapps directory
        COPY ./taxi-booking/target/taxi-booking-1.0.1.war /usr/local/tomcat/webapps  

        # Expose port 8080 for the Tomcat server
        EXPOSE 8080
        ```
        - This Dockerfile uses the **tomcat:9 base image**, copies `taxi-booking-1.0.1.war` to the `/usr/local/tomcat/webapps` directory, and exposes port **8080**.
    - **Create a Docker Repository**   
        - Navigate to  your **Jfrog dashboard**, click `User Profile` in the top-right corner and select **Quick Repository Creation**, now choose **Docker**, click **Next**, provide a **repository prefix** `(e.g., taxi)`, and click **Create** to generate repositories.
    - Copy the code below and add it as a **new stage** in the Pipeline, this stage **Docker Image Creation**, builds two Docker images using the `Dockerfile`: one for `JFrog Artifactory` **(internal storage)** and another for `DockerHub` **(public or external use)**.
        #### `Docker Image Creation Stage`
        - This stage uses `docker.build()`, a built-in function provided by the `Docker Pipeline Plugin`, to build a **Docker image** using the `Dockerfile` in the current working directory. This ensures the application is packaged as a **Docker image** and stored in both **JFrog Artifactory and DockerHub**.
        #### `Add Registry`
        - define the **image names** and **version**
        ```groovy
        def imageNameJfrogArtifact = '<jfrog-docker-artifactory-name/app-name>' (e.g.,'taxi-booking-docker-local/taxi-app')
        def imageNameDocker ='<docker-username/app-name>' (e.g., 'saishandilya/taxi-app')
        def version   = '1.0.1'
        ```
        #### 
        ```groovy
        stage('Docker Image Creation') {
            steps {
                script {
                  app = docker.build(imageNameJfrogArtifact+":"+version)
                  app1 = docker.build(imageNameDocker+":"+version)
                }
            }
        }
        ```
8. **Publish Docker Image**
    - **Add Docker Credentials:** 
        - Go to **Manage Jenkins → Credentials**, select **Global**, and click **Add Credentials**.
        - Select **Kind**: **Username with password** and provide the following details:
            - **Username**: `<your docker hub user name>`
            - **Password**: `<your docker hub password>`
            - **ID**: `docker-creds`  
            - **Description**: docker hub user login credentials.
        - Click **Create**.
    - Copy the code below and add it as a **new stage** in the Pipeline. This stage, **Publish Docker Image**, publishes the previously built Docker images to JFrog Artifactory and DockerHub.
        #### `Publish Docker Image Stage`
        - This stage uses `docker.withRegistry()` to authenticate with **JFrog and DockerHub** using stored credentials and push the built Docker image (app) to the JFrog Artifactory and DockerHub.
        #### `Add Registry`
        ```groovy
        def dockerRegistry='https://index.docker.io/v1/'
        ```
        #### 
        #### 
        ```groovy
        stage('Publish Docker Image') {
            steps {
                script{
                    docker.withRegistry(registry, 'jfrog-token'){
                        app.push()
                    }
                    docker.withRegistry(dockerRegistry, 'docker-creds'){
                        app1.push()
                    }
                }
            }
        }
        ```
9. **Create Container using Docker Image**
    - Copy the code below and add it as a **new stage** in the Pipeline. This stage, **Create Container using Docker Image**, checks for an existing container, removes it if found, and then creates a new one.
        #### `Add Registry`
        ```groovy
        def containerName = imageNameDocker.split('/')[1]
        ```
        #### 
        #### 
        ```groovy
        stage('Create Container using Docker Image') {
            steps {
                sh """
                    echo "Container Name: ${containerName}"
                    # Check if container exists (running or stopped)
                    if [ -n "\$(docker ps -a -q -f name=^${containerName}\$)" ]; then
                        echo "Container ${containerName} is running or stopped. Removing it..."
                        docker rm -f ${containerName}
                    fi
                    echo "Running a new Container Named ${containerName}..."
                    docker run -d --name ${containerName} -p 8000:8080 ${imageNameDocker}:${version}
                    echo "New container ${containerName} is now running."
                """
            }
        }
        ```
10. **Cluster Validation**
    <!-- **Prerequisite:**  -->
    - This stage requires an existing **EKS cluster**. 
        - If you don't have an **EKS cluster** and are setting it up for the first time, or if you *skipped* **Step 7** in `Infrastructure Setup` i.e., **`Deploy EKS`** follow the steps in the [**EKS Cluster Setup Guide**](readmes/eks-cluster-setup.md) to create one. Once completed, return to this step.
        - If an **EKS cluster** already exists, you can skip the creation step and proceed.

    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Cluster Validation** fetches the **EKS cluster** status using **AWS CLI**. If the cluster status is `"ACTIVE"`, it prints a **success message**. If the cluster is either **not found or not active**, it prints an **error message** and **exits** the pipeline with failure.
    - Add **AWS_REGION** and **CLUSTER_NAME** to the `environment` section, allowing users to specify the **region** and **cluster name** to determine where the application should be deployed during the pipeline build.
        ```groovy
        environment {
            AWS_REGION = 'us-east-1'
            CLUSTER_NAME = '<your existing cluster name>' (e.g., taxi booking cluster)
        }
        ```
        #### `Cluster Validation Stage`
        ```groovy
        stage('Cluster Validation') {
            steps {
                sh """
                    CLUSTER_STATUS=\$(aws eks describe-cluster \
                        --region ${AWS_REGION} \
                        --name ${CLUSTER_NAME} \
                        --query 'cluster.status' \
                        --output text 2>/dev/null || echo "NOT_FOUND")

                    if [ "\$CLUSTER_STATUS" != "ACTIVE" ]; then
                        echo "ERROR: EKS Cluster '${CLUSTER_NAME}' is either NOT FOUND or not ACTIVE. Current Status: \$CLUSTER_STATUS"
                        exit 1
                    fi

                    echo "SUCCESS: EKS Cluster '${CLUSTER_NAME}' is: \$CLUSTER_STATUS"
                """
            }
        }
        ```

11. **Generate Kubeconfig File Stage**
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Generate Kubeconfig** creates a kubeconfig file in the pipeline's working directory instead of default location using the AWS CLI, ensuring it's specific to this pipeline. 
    - It then authenticates with the Kubernetes cluster and fetches the **cluster nodes** using `kubectl`.
    - Add the **KUBECONFIG** to the `environment` section.
        ```groovy
        environment {
            KUBECONFIG = './kubeconfig'
        }
        ```
    
        #### `Generate Kubeconfig Stage`
        ```groovy
        stage('Generate Kubeconfig') {
            steps {
                sh """
                    aws eks update-kubeconfig \
                        --region ${AWS_REGION} \
                        --name ${CLUSTER_NAME} \
                        --kubeconfig=${KUBECONFIG}
                """
                sh """
                    echo "Fetching the Nodes:"
                    kubectl get nodes
                """
            }
        }
        ```
<!-- 12. **Application Deployment using Shell**(optional: either shell deployment or Helm charts) -->
12. **Docker Creds Injection Stage**
    - Log into the Jenkins slave machine **(One-time Process)** and authenticate Docker to pull images from the private registry. This is required for Kubernetes secrets.

        *Note: Once completed, this step is not required again unless the Docker login credentials change.*
    - Run the following command, then copy and save the output for later use:
        ```sh
        cat ~/.docker/config.json | base64 -w0
        ```
    - Go to **Manage Jenkins → Manage Credentials**, select **Global**, and click **Add Credentials**.
    - Select **Kind**: **Secret Text** and provide the following details:
        - **Secret**: Copy & Paste generated `Docker credentials (config.json)`. 
        - **ID**: `docker-config-creds`  
        - **Description**: Docker config base 64 encoded credentials.
    - Click **Create**.
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Docker Creds Injection** updates **secret.yaml** in `helm-charts/templates/secret.yaml` folder, replacing .dockerconfigjson value with the generated Docker credentials.

        *Note: For security reasons, credentials are not stored in GitHub; instead, they are injected dynamically during runtime.*
    - Refer to the [**Helm Charts Guide**](readmes/helm-charts.md) for details on using Helm charts to deploy the application on EKS.
        #### `Docker Creds Injection Stage`
        ```groovy
        stage('Docker Creds Injection') {
            steps {
                withCredentials([string(credentialsId: 'docker-config-creds', variable: 'DOCKER_CONFIG_JSON')]) {
                    sh '''
                    sed -i "s|dockerconfigjson: \"\"|dockerconfigjson: \\"$DOCKER_CONFIG_JSON\\"|" ./helm-charts/values.yaml
                    '''
                }
            }
        }
        ```

13. **Deploy Application using Helm Stage**
- Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Deploy Application using Helm** deploys application on EKS cluster using Helm. 
    - If the release already exists, it upgrades the deployment; otherwise, it installs it. 
    - Ensures the namespace exists before deploying the application. 
    - After deployment, lists all namespaces and resources in the specified namespace to verify the deployment.
        #### `Deploy Application using Helm Stage`
        ```groovy
        stage('Deploy Application using Helm') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                sh '''
                    helm upgrade --install <your-release-name(e.g., taxi-booking-release)> ./chart-helm
                    kubectl get ns
                    kubectl get all -n <your-namespace-name(e.g., taxi-app)>
                '''
            }
        }
        ```

14. **Deploy Monitoring Stack using Helm Stage**
- Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Deploy Monitoring Stack using Helm Stage** deploys **Monitoring Stack** `(i.e., prometheus & grafana)` on EKS cluster using Helm.
    - Checks if the **prometheus-community** repository exists; if not, adds it using `helm repo add` and updates it to fetch the latest chart versions.
    - Deploys or upgrades the `kube-prometheus-stack (Prometheus & Grafana)` in the **monitoring** namespace.
    - Uses `monitoring-values.yaml` from the Helm chart folder to override the default service configuration to `LoadBalancer`.
    - Ensures the **monitoring** namespace exists before deploying, then lists all namespaces and resources within it.

        #### `Deploy Monitoring Stack using Helm Stage`
        ```groovy
        stage('Deploy Monitoring Stack using Helm') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                script {
                    def repoName = 'prometheus-community'
                    def repoUrl = 'https://prometheus-community.github.io/helm-charts'

                    def repoExists = sh(
                        script: "helm repo list | grep -w ${repoName}",
                        returnStatus: true
                    ) == 0

                    if (!repoExists) {
                        echo "Adding Helm repo: ${repoName}"
                        sh "helm repo add ${repoName} ${repoUrl}"
                    }

                    sh "helm repo update"
                    
                    // Helm install or upgrade with values.yaml
                    sh '''
                    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
                        --namespace monitoring \
                        --create-namespace \
                        -f ./chart-helm/monitoring-values.yaml
                    '''
                    echo "Monitoring stack deployed successfully!"
                    
                    sh '''
                        kubectl get ns
                        kubectl get all -n monitoring
                    '''
                }
            }
        }
        ```

15. **Uninstall Monitoring Stack & Application using Helm Stage**
- Copy the below provided code and add it as a **new stage** in the Pipeline, this stage **Uninstall Monitoring Stack & Application using Helm Stage** removes **Monitoring Stack** `(i.e., prometheus & grafana)` and **deployed application** on EKS cluster using Helm.

    *Note: This stage is involved during the cleanup process*
    - Uninstalls the **Prometheus monitoring stack** from the `monitoring` namespace.
    - Uninstalls the  **Application** from the `custom namespace` (e.g., taxi-app) namespace.
    - Verify that all resources are removed from both namespaces and Delete the namespaces.

        #### `Uninstall Monitoring Stack & Application using Helm Stage`
        ```groovy
        stage('Uninstall monitoring using helm') {
            when {
                expression { params.ACTION == 'uninstall' }
            }
            steps {
                script {
                    echo "Starting Helm uninstall process..."

                    // Uninstall monitoring stack
                    sh '''
                    echo "Uninstalling Monitoring stack..."
                    helm uninstall prometheus --namespace monitoring || true
                    sleep 30
                    '''

                    // Uninstall custom application
                    sh '''
                    echo "Uninstalling Application..."
                    helm uninstall <your-release-name(e.g., taxi-booking-release)> --namespace <your-namespace-name(e.g., taxi-app)> || true
                    sleep 30
                    '''

                    // Ensure all resources are deleted before removing namespaces
                    sh '''
                    echo "Checking if resources are fully removed..."
                    kubectl get all -n <your-namespace-name(e.g., taxi-app)> || true
                    kubectl get all -n monitoring || true
                    '''

                    // Delete namespaces if empty
                    sh '''
                    echo "Deleting namespaces..."
                    kubectl delete ns <your-namespace-name(e.g., taxi-app)> --ignore-not-found
                    kubectl delete ns monitoring --ignore-not-found
                    '''

                    echo "Uninstallation and cleanup completed!"
                }
            }
        }
        ```

### **3. Jenkinsfile and Webhook Configuration**
1. **Running the Pipeline Directly in Jenkins**  
    - After adding all the above stages to the pipeline, **Validate** the pipeline script and check for any **syntax issues**.  
    - Click **Save & Apply**.  
    - Run the pipeline by clicking **Build with Parameters**. Choose **deploy** to deploy the application or **uninstall** to remove the application.

2. **Using a Jenkinsfile from GitHub**
    - Copy the pipeline stages into a **Jenkinsfile** and push it to your `GitHub repository`. Alternatively, update the existing `Jenkinsfile` in the cloned application repository by replacing it with your custom values.  
    - In Jenkins, navigate to the **Pipeline** section and set **Definition** to `Pipeline Script from SCM`.  
    - Select **SCM** as **Git** and provide the following details:  
    - **Repository URL**: `<your GitHub repository URL>`  
    - **Credentials**: `<your Git credentials>`  
    - **Branches to Build**: `main`  
    - Click **Apply & Save**.

3. **Webhook Configuration**
    - Go to your GitHub **application repository**, click on `Settings`, scroll down to `Code and Automation`, select `Webhooks`, click `Add webhook`, and enter the **required password**.
    - In the `Webhook Configuration` Page, provide the following details:
        - Payload URL: `http://<jenkins-master-public-ip>:8080/github-webhook/`
        - Content type: `application/json`
        - Secret: `Null` **(Leave it empty unless you have a specific secret key)**
        - SSL Verification: `Enable SSL verification`
        - Trigger Events: `Select Just the push event`
        - Click **Add Webhook** to save the configuration.
    - Navigate to the **Jenkins Dashboard**, select the **Pipeline Job**, go to `Configure`, scroll down to `Build Triggers`, check the box for `GitHub hook trigger for GITScm polling`, then click **Apply and Save**.

### **4. Application Validation and Monitoring**
1. **Verify Application Deployment Status**
    - Login to the **Jenkins Slave machine** and run the command:
        ```sh
        kubectl get all -n <custom namespace>
        ```
    - Copy the **Load Balancer URL** or go to AWS console and LoadBalancer and fetch DNS Name.
    - Open a browser and access the application using the ALB URL, appending port 8001 and the application name.
        #### Example:
        ```sh
        http://<LoadBalancer-DNS>:8001/taxi-booking-1.0.1/
        ```
2. **Access Prometheus Dashboard**
    - Run the command on the Jenkins Slave machine:
        ```sh
        kubectl get all -n monitoring
        ```
    - Identify the `service/prometheus-kube-prometheus-prometheus`.
    - Fetch the **LoadBalancer DNS name** and access **Prometheus** on port `9090`.
        ```sh
        http://<LoadBalancer-DNS>:9090
        ```
        *Note: If a security warning appears, click "Continue to site"*
    - Navigate to **Status** > **Targets** to view service details.
3. **Access Grafana Dashboard**
    - From the response of the above command (`kubectl get all -n monitoring`), find `service/prometheus-grafana`.
    - Fetch the **LoadBalancer DNS name** and access **Grafana** (Grafana runs on port 80 by default).
        ```sh
        http://<LoadBalancer-DNS>
        ```
    - Wait a few minutes if the application doesn’t load immediately.
    - **Login Credentials**:
        - **Username:** `admin`
        - **Password:** `prom-operator`

### **5. Cleanup Process**
1. **Uninstall Application and Monitoring Stack**
    - In the **application pipeline**, click `Build with Parameters` and choose **uninstall**.
    - This triggers the `Uninstall monitoring using Helm` stage, which removes the **monitoring stack** and **application**.
2. **EKS Cluster Cleanup**
    - In the **infrastructure pipeline**, click `Build with Parameters` and choose **destroy**.
    - This triggers the `Terraform Destroy` stage, which deletes the **EKS cluster**.
    - The process may take 15–20 minutes to complete.
3. **Infrastucture Cleanup**
    - On the **local machine**, navigate to the `infrastructure` folder.
    - Run the command: `terraform destroy --auto-approve`.
    - This removes the **three EC2 instances** used for the `Ansible` and `Jenkins Master-Slave` configuration.

## **Conclusion**  

Congratulations! 🎉 You have successfully automated the deployment of application on **EKS Cluster**. 

By following this guide, you now have a clear understanding of:

-   **Setting up infrastructure** using Terraform.
-   **Deploying applications** on Kubernetes with Helm.
-   **Monitoring the deployment** using Prometheus and Grafana.
-   **Cleaning up resources** efficiently to optimize cost and management.

Thank you for following along until the end. **Happy Automation!** 🚀