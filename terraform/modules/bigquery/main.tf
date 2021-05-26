provider "google" {
  project = var.project
}


module "testdata" {
  source = "./testdata"

  project = var.project
  env = var.env
  dataset_id = var.dataset_id
  table_id = var.table_id
  beer_table_id = var.beer_table_id
}