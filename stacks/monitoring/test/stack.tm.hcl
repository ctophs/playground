stack {
  name        = "monitoring-test"
  description = "Container workload 'monitoring' in the test environment (s_monitoring_test)"
  id          = "cbe69904-013c-4737-8f7f-a529752c755d"
  tags        = ["monitoring", "test", "container-workload"]
}

globals "azure" {
  environment     = "test"
  subscription_id = global.azure.workload.subscription_ids["test"]
}

globals "azure" "tags" {
  environment = "test"
}
