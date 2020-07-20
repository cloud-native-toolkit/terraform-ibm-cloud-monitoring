provider "ibm" {
  version = ">= 1.2.1"
  region  = var.resource_location
}

provider "helm" {
  version = ">= 1.1.1"
  kubernetes {
    config_path = var.cluster_config_file_path
  }
}

provider "null" {}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  access_key  = ibm_resource_key.sysdig_instance_key[0].credentials["Sysdig Access Key"]
  endpoint    = ibm_resource_key.sysdig_instance_key[0].credentials["Sysdig Collector Endpoint"]
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-sysdig"
  role        = "Manager"
  provision   = var.provision
  bind        = (var.provision || (!var.provision && var.name != "")) && var.cluster_config_file_path != "" && var.cluster_type != ""
  image_url   = var.base_icon_url != "" ? "${var.base_icon_url}/sysdig" : ""
}

// SysDig - Monitoring
resource "ibm_resource_instance" "sysdig_instance" {
  count             = local.provision ? 1 : 0

  name              = local.name
  service           = "sysdig-monitor"
  plan              = var.plan
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = var.tags

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data "ibm_resource_instance" "sysdig_instance" {
  count             = local.bind ? 1 : 0
  depends_on        = [ibm_resource_instance.sysdig_instance]

  name              = local.name
  service           = "sysdig-monitor"
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  location          = var.resource_location
}

resource "ibm_resource_key" "sysdig_instance_key" {
  count = local.bind ? 1 : 0

  name                 = "${local.name}-key"
  resource_instance_id = data.ibm_resource_instance.sysdig_instance[0].id
  role                 = local.role

  //User can increase timeouts 
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "null_resource" "create_sysdig_agent" {
  count      = local.bind ? 1 : 0
  depends_on = [ibm_resource_key.sysdig_instance_key]

  triggers = {
    kubeconfig = var.cluster_config_file_path
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-sysdig.sh ${local.access_key} ${local.endpoint} ${var.namespace} ${var.cluster_type}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-sysdig.sh"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type == "ocp4" && local.bind ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=sysdig || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "helm_release" "sysdig" {
  count      = local.bind ? 1 : 0
  depends_on = [null_resource.create_sysdig_agent, null_resource.delete-consolelink]

  name              = "sysdig"
  chart             = "tool-config"
  namespace         = var.namespace
  repository        = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  timeout           = 1200
  force_update      = true
  replace           = true

  disable_openapi_validation = true

  set {
    name  = "displayName"
    value = "Sysdig"
  }

  set {
    name  = "url"
    value = "https://cloud.ibm.com/observe/monitoring"
  }

  set {
    name  = "imageUrl"
    value = local.image_url
  }

  set {
    name  = "applicationMenu"
    value = true
  }

  set {
    name  = "global.clusterType"
    value = var.cluster_type
  }
}
