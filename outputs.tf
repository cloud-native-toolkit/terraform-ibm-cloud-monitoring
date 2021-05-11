output "id" {
  value       = data.ibm_resource_instance.sysdig_instance.id
  description = "The id of the provisioned instance."
}

output "guid" {
  value       = data.ibm_resource_instance.sysdig_instance.guid
  description = "The id of the provisioned instance."
}

output "name" {
  value       = local.name
  depends_on  = [ibm_resource_instance.sysdig_instance]
  description = "The name of the provisioned instance."
}

output "crn" {
  description = "The id of the provisioned instance"
  value       = data.ibm_resource_instance.sysdig_instance.id
}

output "location" {
  description = "The location of the provisioned instance"
  value       = var.region
  depends_on  = [data.ibm_resource_instance.sysdig_instance]
}

output "service" {
  description = "The service name of the provisioned instance"
  value       = local.service
  depends_on = [data.ibm_resource_instance.sysdig_instance]
}

output "label" {
  description = "The label for the instance"
  value       = var.label
  depends_on = [data.ibm_resource_instance.sysdig_instance]
}

output "key_name" {
  value       = local.name
  depends_on  = [ibm_resource_key.sysdig_instance_key]
  description = "The name of the key provisioned for the Sysdig instance."
}

output "access_key" {
  value       = ibm_resource_key.sysdig_instance_key.credentials["Sysdig Access Key"]
  description = "The access key for the Sysdig instance."
  sensitive   = true
}
