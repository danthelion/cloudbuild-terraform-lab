terraform {
  backend "gcs" {
    bucket = "dptraining5-tfstate"
    prefix = "env/prod"
  }
}
