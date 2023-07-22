terraform {
  backend "s3" {
    bucket = "pipeline-tfstate"
    key    = "pipeline/terraform.tfstate"
    region = "ap-northeast-2"
  }
}