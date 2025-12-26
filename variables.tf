variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vm_count" {
  type = number
}

variable "vm_name_prefix" {
  type = string
}

variable "shared_vnet_cidr" {
  type = list(string)
}

variable "test_vnet_cidr" {
  type = list(string)
}

variable "shared_subnet_cidr" {
  type = list(string)
}

variable "test_subnet_cidr" {
  type = list(string)
}
