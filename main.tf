
resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "tools_resource_group" {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

locals {
  tmp_dir     = "${path.cwd}/.tmp"
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-sysdig"
  role        = "Manager"
  provision   = var.provision
}

// SysDig - Monitoring
resource "ibm_resource_instance" "sysdig_instance" {
  count             = local.provision ? 1 : 0

  name              = local.name
  service           = "sysdig-monitor"
  plan              = var.plan
  location          = var.region
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
  location          = var.region
}
