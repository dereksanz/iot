provider "google" {
  credentials = file("~/terraform-key.json")
  project     = var.project
  region      = var.region
  version     = "~> 3.5"
}

provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  version                = "~> 1.13"
}

resource "google_container_cluster" "primary" {
  name               = "primary-cluster"
  location           = var.region
  initial_node_count = 3

  node_config {
    machine_type = "n1-standard-1"
    disk_size_gb = 50
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  node_count = 3
  location   = google_container_cluster.primary.location

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

data "google_client_config" "default" {}

resource "kubernetes_namespace" "iot" {
  metadata {
    name = "iot-namespace"
  }
}

resource "kubernetes_deployment" "iot_simulator" {
  depends_on = [kubernetes_namespace.iot]

  metadata {
    name      = "iot-simulator"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "iot-simulator"
      }
    }
    template {
      metadata {
        labels = {
          app = "iot-simulator"
        }
      }
      spec {
        container {
          name  = "iot-simulator"
          image = "gcr.io/airy-runway-128422/iot-simulator:latest" # Update with your Docker image
          env {
            name  = "KAFKA_BOOTSTRAP_SERVERS"
            value = "kafka-service:9092"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "iot_simulator" {
  metadata {
    name      = "iot-simulator-service"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    selector = {
      app = "iot-simulator"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.iot.metadata[0].name
    labels = {
      app = "kafka"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kafka"
      }
    }
    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }
      spec {
        container {
          name  = "kafka"
          image = "confluentinc/cp-kafka:latest"
          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "zookeeper-service:2181"
          }
          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka-service:9092"
          }
          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092"
          }
          env {
            name  = "KAFKA_DEFAULT_REPLICATION_FACTOR"
            value = "1"
          }
          env {
            name  = "KAFKA_MIN_INSYNC_REPLICAS"
            value = "1"
          }
          port {
            container_port = 9092
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka-service"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    selector = {
      app = "kafka"
    }
    port {
      port        = 9092
      target_port = 9092
    }
  }
}

resource "kubernetes_deployment" "zookeeper" {
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "zookeeper"
      }
    }
    template {
      metadata {
        labels = {
          app = "zookeeper"
        }
      }
      spec {
        container {
          name  = "zookeeper"
          image = "confluentinc/cp-zookeeper:latest"
          env {
            name  = "ZOOKEEPER_CLIENT_PORT"
            value = "2181"
          }
          port {
            container_port = 2181
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "zookeeper" {
  metadata {
    name      = "zookeeper-service"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    selector = {
      app = "zookeeper"
    }
    port {
      port        = 2181
      target_port = 2181
    }
  }
}

resource "kubernetes_job" "kafka_topic_creation" {
  metadata {
    name      = "kafka-topic-creation"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    backoff_limit = 4
    template {
      metadata {
        name = "kafka-topic-creation"
      }
      spec {
        restart_policy = "OnFailure"
        container {
          name  = "kafka-topic-creator"
          image = "confluentinc/cp-kafka:latest"
          command = [
            "sh", "-c", 
            "kafka-topics --create --if-not-exists --bootstrap-server kafka-service:9092 --replication-factor 1 --partitions 50 --topic __consumer_offsets --config compression.type=producer --config cleanup.policy=compact --config segment.bytes=104857600 && sleep 10"
          ]
          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka-service:9092"
          }
        }
      }
    }
  }
}

resource "google_bigquery_dataset" "iot_dataset" {
  dataset_id = "iot_dataset"
  project    = var.project
}

resource "google_bigquery_table" "iot_table" {
  table_id   = "iot_table"
  dataset_id = google_bigquery_dataset.iot_dataset.dataset_id
  project    = var.project

  schema = <<EOF
[
  {
    "name": "sensor_id",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "temperature",
    "type": "FLOAT",
    "mode": "REQUIRED"
  },
  {
    "name": "humidity",
    "type": "FLOAT",
    "mode": "REQUIRED"
  },
  {
    "name": "motion",
    "type": "BOOLEAN",
    "mode": "REQUIRED"
  },
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "REQUIRED"
  }
]
EOF
}

resource "kubernetes_deployment" "pyspark" {
  metadata {
    name      = "pyspark-job"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "pyspark-job"
      }
    }
    template {
      metadata {
        labels = {
          app = "pyspark-job"
        }
      }
      spec {
        container {
          name  = "pyspark-job"
          image = "gcr.io/airy-runway-128422/pyspark-job:latest" # Update with your Docker image
          env {
            name  = "GOOGLE_APPLICATION_CREDENTIALS"
            value = "/credentials/credentials.json"
          }
          volume_mount {
            mount_path = "/credentials"
            name       = "gcp-credentials"
          }
        }
        volume {
          name = "gcp-credentials"
          secret {
            secret_name = "gcp-credentials"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pyspark_job" {
  metadata {
    name      = "pyspark-job-service"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  spec {
    selector = {
      app = "pyspark-job"
    }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_secret" "gcp_credentials" {
  metadata {
    name      = "gcp-credentials"
    namespace = kubernetes_namespace.iot.metadata[0].name
  }
  data = {
    "credentials.json" = file("~/terraform-key.json")
  }
}

