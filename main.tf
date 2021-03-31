provider "ibm" {
  version = ">= 1.9.0"
  region  = var.region
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
  tmp_dir     = "${path.cwd}/.tmp"
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-sysdig"
  role        = "Manager"
  provision   = var.provision
  bind        = (var.provision || (!var.provision && var.name != "")) && var.cluster_name != ""
  access_key  = local.bind ? ibm_resource_key.sysdig_instance_key[0].credentials["Sysdig Access Key"] : ""
  cluster_type_file = "${local.tmp_dir}/cluster_type.out"
  cluster_type      = data.local_file.cluster_type.content
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
  count             = local.bind ? 1 : 0
  depends_on        = [ibm_resource_instance.sysdig_instance]

  name              = local.name
  service           = "sysdig-monitor"
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  location          = var.region
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

resource "null_resource" "setup-ob-plugin" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/setup-ob-plugin.sh"
  }
}

resource "null_resource" "sysdig_bind" {
  count = local.bind ? 1 : 0
  depends_on = [null_resource.setup-ob-plugin]

  triggers = {
    cluster_id  = var.cluster_id
    instance_id = data.ibm_resource_instance.sysdig_instance[0].guid
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bind-instance.sh ${self.triggers.cluster_id} ${self.triggers.instance_id} ${local.access_key} ${var.private_endpoint}"

    environment = {
      SYNC = var.sync
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/unbind-instance.sh ${self.triggers.cluster_id} ${self.triggers.instance_id}"
  }
}

resource null_resource create_tmp_dir {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }
}

resource null_resource cluster_type {
  depends_on = [null_resource.create_tmp_dir]

  provisioner "local-exec" {
    command = "kubectl api-resources -o name | grep consolelink && echo -n 'ocp4' > ${local.cluster_type_file}"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

data local_file cluster_type {
  depends_on = [null_resource.cluster_type]

  filename = local.cluster_type_file
}

resource "null_resource" "delete-consolelink" {
  count = local.bind ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl api-resources -o name | grep consolelink && kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=sysdig || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file_path
    }
  }
}

resource "helm_release" "sysdig" {
  count      = local.bind ? 1 : 0
  depends_on = [null_resource.sysdig_bind, null_resource.delete-consolelink]

  name              = "sysdig"
  chart             = "tool-config"
  namespace         = var.tools_namespace
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
    name  = "applicationMenu"
    value = true
  }

  set {
    name  = "global.clusterType"
    value = local.cluster_type
  }
}
