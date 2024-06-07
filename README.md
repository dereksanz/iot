# IoT Sensor Data Simulation with Kubernetes and Kafka

## Overview

This project demonstrates the deployment of an IoT sensor data simulator on a Kubernetes cluster hosted on Google Cloud Platform (GCP). The infrastructure is defined and managed using Terraform, and the deployment includes setting up Kafka and Zookeeper for data streaming and storage.

## Components

1. **Google Cloud Provider Configuration**
   - Configures Google Cloud provider in Terraform using service account credentials.
   - Specifies the project and region for the resources.

2. **Kubernetes Provider Configuration**
   - Configures the Kubernetes provider to interact with the GKE (Google Kubernetes Engine) cluster.
   - Utilizes the cluster endpoint and authentication details.

3. **Google Kubernetes Engine (GKE) Cluster**
   - Creates a GKE cluster named `primary-cluster` with an initial node count of 3.
   - Configures node pool with preemptible nodes to save costs.

4. **Kubernetes Namespace**
   - Creates a namespace `iot-namespace` to logically separate the IoT application resources.

5. **Kafka and Zookeeper Deployments**
   - Deploys Kafka and Zookeeper within the `iot-namespace`.
   - Configures environment variables for Kafka and Zookeeper to communicate and function correctly.
   - Exposes Kafka and Zookeeper services within the cluster.

6. **IoT Simulator Deployment**
   - Deploys the IoT simulator application within the `iot-namespace`.
   - The simulator generates random sensor data and sends it to Kafka.
   - Configures environment variables to connect the simulator to Kafka.

7. **Kafka Topic Creation Job**
   - Creates a Kubernetes job to set up necessary Kafka topics for storing sensor data.
   - Ensures topics are created with appropriate configurations.
