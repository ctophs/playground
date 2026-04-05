# ---------------------------------------------------------------------------
# Code generation for stacks tagged "container-workload".
# Generates _tm_main.tf, which composes the individual Azure modules into
# the full container workload pattern:
#   2x Resource Group (identities, apps)
#   1x User Assigned Identity for the Container App Environment
#   1x Container App Environment (Consumption profile, internal LB)
#   Nx User Assigned Identity — one per container app (from globals)
#   Nx Container App             — one per container app (from globals)
# ---------------------------------------------------------------------------

generate_hcl "_tm_main.tf" {
  condition = tm_contains(terramate.stack.tags, "container-workload")

  content {
    locals {
      workload    = global.azure.workload.name
      environment = global.azure.environment
      location    = global.azure.location
      tags        = global.azure.tags

      # Container apps map — defined in workload globals, e.g.:
      #   { gatus = { image = "...", port = 8080 }, nginx = { image = "...", port = 80 } }
      # Terraform iterates this map at plan time via for_each.
      container_apps = global.azure.workload.container_apps
    }

    # ------------------------------------------------------------------
    # Resource Groups
    # ------------------------------------------------------------------

    module "rg_identities" {
      source   = "${global.terraform.modules.resource_group.source}?ref=${global.terraform.modules.resource_group.version}"
      name     = "rg-${global.azure.workload.name}-${global.azure.environment}-identities"
      location = global.azure.location
      tags     = global.azure.tags
    }

    module "rg_apps" {
      source   = "${global.terraform.modules.resource_group.source}?ref=${global.terraform.modules.resource_group.version}"
      name     = "rg-${global.azure.workload.name}-${global.azure.environment}-apps"
      location = global.azure.location
      tags     = global.azure.tags
    }

    # ------------------------------------------------------------------
    # User Assigned Identity for the Container App Environment
    # ------------------------------------------------------------------

    module "uami_cae" {
      source              = "${global.terraform.modules.user_assigned_identity.source}?ref=${global.terraform.modules.user_assigned_identity.version}"
      name                = "id-cae-${global.azure.workload.name}-${global.azure.environment}"
      resource_group_name = module.rg_identities.name
      location            = global.azure.location
      tags                = global.azure.tags
    }

    # ------------------------------------------------------------------
    # Container App Environment
    # ------------------------------------------------------------------

    module "cae" {
      source                   = "${global.terraform.modules.container_app_environment.source}?ref=${global.terraform.modules.container_app_environment.version}"
      name                     = "cae-${global.azure.workload.name}-${global.azure.environment}"
      resource_group_name      = module.rg_apps.name
      location                 = global.azure.location
      uami_id                  = module.uami_cae.id
      infrastructure_subnet_id = tm_try(global.azure.workload.subnet_id, null)
      tags                     = global.azure.tags
    }

    # ------------------------------------------------------------------
    # User Assigned Identities — one per container app
    # ------------------------------------------------------------------

    module "uami_apps" {
      for_each            = local.container_apps
      source              = "${global.terraform.modules.user_assigned_identity.source}?ref=${global.terraform.modules.user_assigned_identity.version}"
      name                = "id-ca-${each.key}-${local.workload}-${local.environment}"
      resource_group_name = module.rg_identities.name
      location            = local.location
      tags                = local.tags
    }

    # ------------------------------------------------------------------
    # Container Apps — one per entry in container_apps map
    # ------------------------------------------------------------------

    module "container_app" {
      for_each                     = local.container_apps
      source                       = "${global.terraform.modules.container_app.source}?ref=${global.terraform.modules.container_app.version}"
      name                         = "ca-${each.key}-${local.workload}-${local.environment}"
      resource_group_name          = module.rg_apps.name
      container_app_environment_id = module.cae.id
      uami_id                      = module.uami_apps[each.key].id
      image                        = each.value.image
      port                         = each.value.port
      location                     = local.location
      tags                         = local.tags
    }
  }
}
