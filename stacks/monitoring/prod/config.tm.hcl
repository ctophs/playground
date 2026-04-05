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
