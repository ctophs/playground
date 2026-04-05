# ---------------------------------------------------------------------------
# Workload-level globals for "monitoring".
# Inherited by all child stacks (test, prod, dev).
# ---------------------------------------------------------------------------

globals "azure" "workload" {
  name = "monitoring"

  # One subscription per environment — replace with real subscription IDs.
  subscription_ids = {
    test = "11111111-1111-1111-1111-111111111111"
    prod = "22222222-2222-2222-2222-222222222222"
  }

  # Container apps deployed into every environment of this workload.
  # Add or remove entries here to change the set of apps — no module code changes needed.
  container_apps = {
    gatus = {
      image = "ghcr.io/twinproduction/gatus:latest"
      port  = 8080
    }
    nginx = {
      image = "nginx:1.27-alpine"
      port  = 80
    }
  }

  # Optional: set subnet_id to enable VNet integration for the Container App Environment.
  # The subnet must be at least /27 and delegated to Microsoft.App/environments.
  # subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
}

globals "azure" "tags" {
  workload = "monitoring"
}
