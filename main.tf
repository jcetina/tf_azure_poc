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
    organization = var.TERRAFORM_ORG

    workspaces {
      name = var.TERRAFORM_WORKSPACE
    }
  }

}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "demo" {
  name     = "demorg"
  location = "eastus"

}
