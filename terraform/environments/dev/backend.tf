terraform {
  backend "gcs" {
    bucket = "daniel-palma-sandbox-tfstate"
    prefix = "env/dev"
  }
}
