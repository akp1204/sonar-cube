terraform {
  backend "s3" {
    bucket         = "sonarqube-terraform"
    key            = "sonarqube/sonarqube.tfstate"
    dynamodb_table = "terraform_state"
    region         = "us-east-1"
  }
}

