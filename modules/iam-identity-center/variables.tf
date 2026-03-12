# Variables for IAM Identity Center module

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
