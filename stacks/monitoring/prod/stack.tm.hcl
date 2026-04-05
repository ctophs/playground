stack {
  name        = "monitoring-prod"
  description = "Container workload 'monitoring' in the prod environment (s_monitoring_prod)"
  id          = "00f80ea1-27a6-427d-a8f6-18a7dc1e467d"
  tags        = ["monitoring", "prod", "container-workload"]
}

globals "azure" {
  environment     = "prod"
  subscription_id = global.azure.workload.subscription_ids["prod"]
}

globals "azure" "tags" {
  environment = "prod"
}

# To pin specific image versions in prod, override container_apps here:
# globals "azure" "workload" {
#   container_apps = {
#     gatus = {
#       image = "ghcr.io/twinproduction/gatus:v5.12.0"
#       port  = 8080
#     }
#     nginx = {
#       image = "nginx:1.27-alpine"
#       port  = 80
#     }
#   }
# }
