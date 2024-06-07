# Use the Bitnami Spark image as a parent image
FROM bitnami/spark:3.1.2

# Install python3 and pip3
USER root
RUN install_packages python3-pip

# Install Python packages
RUN pip3 install google-cloud-bigquery kafka-python

# Install curl
RUN install_packages curl

# Download the GCS connector using curl
RUN curl -o $SPARK_HOME/jars/gcs-connector-hadoop2-2.2.2.jar https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop2-2.2.2/gcs-connector-hadoop2-2.2.2.jar

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Set the entrypoint to run the Spark application
ENTRYPOINT ["spark-submit"]

# Run the application with required packages
CMD ["--packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2,com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.21.1", "/app/spark_kafka_to_bigquery.py"]

