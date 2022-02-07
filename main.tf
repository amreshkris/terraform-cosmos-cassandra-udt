# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.85"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
  required_version = ">= 0.15.3"
}

provider "azurerm" {
  features {}
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
