variable "owner" {
  description = "Stack Owner"
  type        = string
  default     = "fj"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 3
}

variable "cloud_pub" {
  description = "SSH Public Key"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH Private Key"
  type        = string
  sensitive   = true
}
