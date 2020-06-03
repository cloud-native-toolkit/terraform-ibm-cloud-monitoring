provider "ibm" {
  version = ">= 1.2.1"
}

provider "null" {}

data "ibm_resource_group" "tools_resource_group" {
  name = var.resource_group_name
}

locals {
  access_key  = ibm_resource_key.sysdig_instance_key.credentials["Sysdig Access Key"]
  endpoint    = ibm_resource_key.sysdig_instance_key.credentials["Sysdig Collector Endpoint"]
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-sysdig"
}

// SysDig - Monitoring
resource "ibm_resource_instance" "sysdig_instance" {
  count             = var.exists ? 0 : 1

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
  depends_on        = [ibm_resource_instance.sysdig_instance]

  name              = local.name
  service           = "sysdig-monitor"
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  location          = var.resource_location
}

resource "ibm_resource_key" "sysdig_instance_key" {
  name                 = "${data.ibm_resource_instance.sysdig_instance.name}-key"
  resource_instance_id = data.ibm_resource_instance.sysdig_instance.id
  role = "Manager"

  //User can increase timeouts 
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

resource "null_resource" "create_sysdig_agent" {
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
