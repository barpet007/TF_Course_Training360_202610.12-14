variable "storage_name" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "replication" {
  type    = string
  default = "LRS"
}