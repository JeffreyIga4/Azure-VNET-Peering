location              = "canadacentral"
resource_group_name   = "peer-rg"
vm_count              = 2
vm_name_prefix        = "peer"

shared_vnet_cidr = ["10.0.0.0/16"]
shared_subnet_cidr = ["10.0.1.0/24"]

test_vnet_cidr = ["10.1.0.0/16"]
test_subnet_cidr = ["10.1.0.0/24"]
bastion_subnet_cidr = ["10.0.0.0/26"]
