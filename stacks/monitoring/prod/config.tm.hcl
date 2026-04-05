globals "azure" {
  environment     = "prod"
  subscription_id = global.azure.workload.subscription_ids["prod"]
}

globals "azure" "tags" {
  environment = "prod"
}

# To override any container app values in prod (image versions, ports, etc.),
# redefine the full container_apps map here — Terramate replaces maps entirely:
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
