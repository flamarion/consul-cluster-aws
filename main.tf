terraform {
  required_providers {
    aws      = "~> 3.22"
    random   = "~> 3.0"
    template = "~> 2.2"
    null     = "~> 3.1"
  }
  required_version = "~> 1.0"

  backend "remote" {
    organization = "FlamaCorp"

    workspaces {
      name = "tf-aws-consul-cluster"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "FlamaCorp"
    workspaces = {
      name = "tf-aws-vpc"
    }
  }
}

resource "aws_key_pair" "tfe_key" {
  key_name   = "${var.owner}-consul"
  public_key = var.cloud_pub
}

