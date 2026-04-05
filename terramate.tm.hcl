terramate {
  required_version = ">= 0.11.0"

  config {
    git {
      default_branch = "master"
    }

    run {
      env {
        # Cache provider plugins across stacks to avoid re-downloading on each init.
        TF_PLUGIN_CACHE_DIR = "${terramate.root.path.fs.absolute}/.terraform-plugin-cache"
      }
    }
  }
}
