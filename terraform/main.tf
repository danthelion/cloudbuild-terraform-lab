provider "google" {
  project = var.project
}

module "bigquery" {
  source = "./modules/bigquery"
  project = var.project
  dataset_id = var.dataset_id
  table_id = var.table_id
  env = var.env
  deletion_protection = var.deletion_protection
  beer_table_id = var.beer_table_id
}

//module "pubsub" {
//  source = "./modules/pubsub"
//  project = var.project
//  dataset_id = var.dataset_id
//  table_id = var.table_id
//  env = var.env
//  deletion_protection = var.deletion_protection
//}
//
//module "cloudfunctions" {
//  source = "./modules/cloudfunctions"
//  project = var.project
//  dataset_id = var.dataset_id
//  table_id = var.table_id
//  env = var.env
//  deletion_protection = var.deletion_protection
//  beer_table_id = var.beer_table_id
//}