resource "google_bigquery_dataset" "testdata_dataset" {
  project = var.project
  dataset_id = "${var.dataset_id}_${var.env}"
  friendly_name = "test"
  description = "This is a test description"
  location = "EU"

}

resource "google_bigquery_table" "testdata_table" {
  dataset_id = google_bigquery_dataset.testdata_dataset.dataset_id
  project = var.project
  table_id = var.table_id
  schema = file("${path.module}/testtable.json")
}