terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      version = ">= 2.28.1"
    }
    random = {
      version = "~> 2.1"
    }
    local = {
      version = "~> 1.2"
    }
    null = {
      version = "~> 2.1"
    }
    template = {
      version = "~> 2.1"
    }
    kubernetes = {
      version = "~> 2.0"
    }
  }
}
