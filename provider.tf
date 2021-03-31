provider "ibm" {
  region  = var.region
}

provider "helm" {
  kubernetes {
    config_path = var.cluster_config_file_path
  }
}

provider "null" {}
