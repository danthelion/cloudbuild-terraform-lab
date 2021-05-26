terraform {
  backend "gcs" {
    bucket = "dptraining1-tfstate"
    prefix = "env/dev"
  }
}
