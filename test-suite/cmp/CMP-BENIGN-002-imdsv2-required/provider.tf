provider "aws" {
  region  = var.region
  profile = var.profile != "" ? var.profile : null

  # Automatically applies tags to all taggable resources.
  default_tags {
    tags = local.common_tags
  }
}
