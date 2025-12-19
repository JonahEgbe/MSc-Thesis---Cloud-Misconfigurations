variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "eu-west-2"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile name to use (must exist in ~/.aws/config)"
  default     = "terraform-user"
}

# Scenario metadata (used for tagging + results aggregation)
variable "scenario_id" {
  type        = string
  description = "Scenario identifier (e.g., STO-MISC-001-s3-public-unencrypted)"
}

variable "domain" {
  type        = string
  description = "Domain code (STO, IAM, NET, LOG, CMP)"
}

variable "type" {
  type        = string
  description = "Scenario type (BENIGN or MISC)"
}

# Optional: comma-separated mapping to CIS controls/benchmarks
variable "cis_controls" {
  type        = string
  description = "Optional CIS mapping (e.g., S3.8,S3.17)"
  default     = ""
}
