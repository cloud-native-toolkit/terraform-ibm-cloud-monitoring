terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.23.1"
    }
    helm = {
      version = ">= 1.1.1"
    }
  }
  required_version = ">= 0.13"
}
