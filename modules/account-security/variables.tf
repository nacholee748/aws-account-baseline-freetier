# Variables for account-security module

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
