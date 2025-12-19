provider "aws" {
  region  = var.region
  profile = var.profile

  # Automatically applies tags to all taggable resources.
  default_tags {
    tags = local.common_tags
  }
}
