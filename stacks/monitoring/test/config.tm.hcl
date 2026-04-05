globals "azure" {
  environment     = "test"
  subscription_id = global.azure.workload.subscription_ids["test"]
}

globals "azure" "tags" {
  environment = "test"
}
