resource "google_project_service" "enable_cloudfunctions" {
  project = var.project
  service = "cloudfunctions.googleapis.com"
}

resource "google_storage_bucket" "archive_bucket" {
  project = var.project
  name = "${var.project}-loader-function"
  location = "EU"
}

data "archive_file" "cloudfunction_zip" {
  type        = "zip"
  output_path = "${path.module}/loader.zip"
  source_dir = "${path.module}/loader"
}

resource "google_storage_bucket_object" "archive" {
  name   = "loader"
  bucket = google_storage_bucket.archive_bucket.name
  source = data.archive_file.cloudfunction_zip.output_path
}

resource "google_cloudfunctions_function" "data-loader" {
  depends_on = [google_project_service.enable_cloudfunctions]
  project     = var.project
  name        = "data-upload-handler"
  description = "Function to handle new data published to a topic."
  runtime     = "python39"

  source_archive_bucket = google_storage_bucket.archive_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point           = "hello_pubsub"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.project}/topics/bq-ingestion-topic"
    failure_policy {
      retry = true
    }
  }

  region = "europe-west3"
}