# IoT Data Simulation and Streaming to BigQuery

This repository contains the code and configurations for simulating IoT sensor data, streaming it to a Kafka topic, processing it with PySpark, and storing the results in a BigQuery table. The infrastructure is managed using Terraform on Google Cloud Platform (GCP) and Kubernetes.

## Directory Structure
- `iot_data_simulation/`: Contains the Python script to simulate IoT data and send it to Kafka.
- `kafka_to_spark/`: Contains the Dockerfile and PySpark script to read from Kafka and write to BigQuery.
- `terraform-gcp/`: Contains the Terraform configuration files for setting up the necessary GCP and Kubernetes resources.

## Components
### Terraform (terraform-gcp/)
This directory contains the Terraform scripts to set up:
1. A GCP Kubernetes cluster.
2. Kubernetes deployments for Kafka, Zookeeper, IoT data simulator, and PySpark job.
3. BigQuery dataset and table.

#### Key Files:
- `main.tf`: Main Terraform configuration file setting up all the necessary infrastructure.

### IoT Data Simulation (iot_data_simulation/)
This directory contains a Python script that simulates IoT sensor data and sends it to a Kafka topic.

#### Key Files:
- `iot_data_simulation.py`: Python script for generating and sending sensor data to Kafka.

### Kafka to Spark Streaming (kafka_to_spark/)
This directory contains the Dockerfile and PySpark script to read data from Kafka, process it, and write it to BigQuery.

#### Key Files:
- `Dockerfile`: Dockerfile to create an image with PySpark and required dependencies.
- `spark_kafka_to_bigquery.py`: PySpark script to read from Kafka, process the data, and write it to BigQuery.

## Infrastructure Setup
1. **Kubernetes Cluster**: The Terraform script sets up a Kubernetes cluster on GCP.
2. **Kafka & Zookeeper**: Kafka and Zookeeper deployments are created to handle the messaging.
3. **IoT Data Simulator**: A deployment for the IoT data simulator which generates and sends data to Kafka.
4. **PySpark Job**: A deployment for the PySpark job which processes Kafka messages and stores them in BigQuery.
5. **BigQuery**: A BigQuery dataset and table are created to store the processed data.

## Running the Simulation
1. **Deploy IoT Simulator**: Deploy the IoT data simulator to generate sensor data.
2. **Deploy PySpark Job**: Deploy the PySpark job to process Kafka messages and write to BigQuery.
3. **Set up the Infrastructure**: Run the Terraform scripts to set up the required infrastructure.
