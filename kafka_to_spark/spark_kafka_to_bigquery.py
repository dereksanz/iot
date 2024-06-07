from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col
import os
import json
import logging

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Set up the environment variable for Google Application Credentials
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/credentials/credentials.json"

# Create Spark session
spark = SparkSession.builder \
    .appName("KafkaToBigQuery") \
    .getOrCreate()

logger.info("Spark session started")

# Read from Kafka
logger.info("Reading from Kafka...")
kafka_df = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "kafka-service:9092") \
    .option("subscribe", "iot-sensor-data") \
    .load()

logger.info("Successfully connected to Kafka")

# Define schema for Kafka messages (adjust based on your message structure)
schema = "sensor_id STRING, value DOUBLE, timestamp STRING"

# Parse Kafka messages
logger.info("Parsing Kafka messages")
json_df = kafka_df.selectExpr("CAST(value AS STRING) as json").select(from_json(col("json"), schema).alias("data")).select("data.*")

# Define function to write to BigQuery
def write_to_bigquery(df, epoch_id):
    df.write \
        .format("bigquery") \
        .option("table", "airy-runway-128422.iot_dataset.iot_table") \
        .option("temporaryGcsBucket", "your_temp_gcs_bucket") \
        .mode("append") \
        .save()

# Start the stream and write to BigQuery
logger.info("Starting write stream to BigQuery...")
query = json_df.writeStream \
    .foreachBatch(write_to_bigquery) \
    .start()

logger.info("Stream started, awaiting termination...")
query.awaitTermination()

