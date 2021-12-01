# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 0.14.9"


  backend "remote" {
    organization = "cetinas-dot-org"

    workspaces {
      name = "tf_azure_poc"
    }
  }

}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "demo" {
  name     = "demo"
  location = "eastus"

}
