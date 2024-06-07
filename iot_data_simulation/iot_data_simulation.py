import time
import random
import json
import logging
from datetime import datetime
from kafka import KafkaProducer

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

KAFKA_TOPIC = "iot-sensor-data"
KAFKA_BOOTSTRAP_SERVERS = "kafka-service:9092"

try:
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        request_timeout_ms=120000
    )
    logger.info("Kafka producer created successfully")
except Exception as e:
    logger.error(f"Failed to create Kafka producer: {e}")
    raise

def generate_sensor_data():
    sensor_id = random.randint(1, 100)
    temperature = round(random.uniform(20.0, 30.0), 2)
    humidity = round(random.uniform(30.0, 50.0), 2)
    motion = random.choice([True, False])
    timestamp = datetime.utcnow().isoformat()
    return {
        "sensor_id": sensor_id,
        "temperature": temperature,
        "humidity": humidity,
        "motion": motion,
        "timestamp": timestamp
    }

def simulate_iot_data():
    while True:
        try:
            sensor_data = generate_sensor_data()
            producer.send(KAFKA_TOPIC, sensor_data)
            logger.info(f"Produced: {sensor_data}")
        except Exception as e:
            logger.error(f"Failed to send data to Kafka: {e}")
        time.sleep(5)

if __name__ == "__main__":
    simulate_iot_data()

