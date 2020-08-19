module "dev_sysdig" {
  source = "./module"

  resource_group_name      = var.resource_group_name
  resource_location        = var.region
  provision                = true
  cluster_id               = module.dev_cluster.id
  cluster_name             = module.dev_cluster.name
  cluster_type             = module.dev_cluster.type_code
  cluster_config_file_path = module.dev_cluster.config_file_path
  tools_namespace          = module.dev_capture_state.namespace
  name_prefix              = var.name_prefix
}
