terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "random" {}

locals {
  formatted_string = "${var.prefix}-${random_string.main.result}"
}

resource "random_string" "main" {
  length  = var.string_length
  special = false
  upper   = false
}

