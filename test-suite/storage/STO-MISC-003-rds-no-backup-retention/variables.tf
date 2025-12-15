variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS region for deployment"
}

variable "profile" {
  type        = string
  default     = "terraform_user"
  description = "AWS CLI profile to use"
}
