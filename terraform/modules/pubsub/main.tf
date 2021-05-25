resource "google_pubsub_topic" "bq-ingestion-topic" {
  project = var.project
  name = "bq-ingestion-topic"
}