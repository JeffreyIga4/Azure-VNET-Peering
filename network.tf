# Shared VNet (Hub)
resource "azurerm_virtual_network" "shared" {
  name                = "shared-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.shared_vnet_cidr
}

resource "azurerm_subnet" "shared_subnet" {
  name                 = "shared-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = var.shared_subnet_cidr
}

# Test VNet
resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.test_vnet_cidr
}

resource "azurerm_subnet" "test_subnet" {
  name                 = "test-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = var.test_subnet_cidr
}

# VNet Peering: Shared → Test
resource "azurerm_virtual_network_peering" "shared_to_test" {
  name                      = "shared-to-test"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.shared.name
  remote_virtual_network_id = azurerm_virtual_network.test.id

  allow_virtual_network_access = true
}

# VNet Peering: Test → Shared
resource "azurerm_virtual_network_peering" "test_to_shared" {
  name                      = "test-to-shared"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.test.name
  remote_virtual_network_id = azurerm_virtual_network.shared.id

  allow_virtual_network_access = true
}

# NICs for VMs in test subnet
resource "azurerm_network_interface" "nic" {
  count = var.vm_count

  name                = "${var.vm_name_prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
