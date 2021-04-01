module "dev_sysdig" {
  source = "./module"

  resource_group_name      = var.resource_group_name
  region                   = var.region
  provision                = true
  name_prefix              = var.name_prefix
}
