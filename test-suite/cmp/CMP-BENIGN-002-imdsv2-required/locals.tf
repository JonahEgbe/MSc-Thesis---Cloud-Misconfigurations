resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  # Use a short suffix so globally-unique AWS names
  name_suffix = random_id.suffix.hex

  # Common tags for every resource in this scenario
  common_tags = {
    scenario_id  = var.scenario_id
    domain       = var.domain
    type         = var.type
    cis_controls = var.cis_controls
  }
}
