variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region for deployment"
}

variable "profile" {
  type        = string
  default     = ""
  description = "AWS CLI profile to use"
}
