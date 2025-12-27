# =========================
# Shared VNet (Hub)
# =========================
resource "azurerm_virtual_network" "shared" {
  name                = "shared-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.shared_vnet_cidr
}

resource "azurerm_subnet" "shared_subnet" {
  name                 = "shared-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = var.shared_subnet_cidr
}


resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = var.bastion_subnet_cidr
}

# =========================
# Test VNet (Spoke)
# =========================
resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.test_vnet_cidr
}

resource "azurerm_subnet" "test_subnet" {
  name                 = "test-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = var.test_subnet_cidr
}

# =========================
# VNet Peering
# =========================
resource "azurerm_virtual_network_peering" "shared_to_test" {
  name                      = "shared-to-test"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.shared.name
  remote_virtual_network_id = azurerm_virtual_network.test.id

  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "test_to_shared" {
  name                      = "test-to-shared"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.test.name
  remote_virtual_network_id = azurerm_virtual_network.shared.id

  allow_virtual_network_access = true
}

# =========================
# Bastion (Hub)
# =========================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "shared-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_security_group" "test_nsg" {
  name                = "test-subnet-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-From-Shared-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.shared_vnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "test_subnet_nsg" {
  subnet_id                 = azurerm_subnet.test_subnet.id
  network_security_group_id = azurerm_network_security_group.test_nsg.id
}


# =========================
# NICs for VMs in test subnet
# =========================
resource "azurerm_network_interface" "nic" {
  count = var.vm_count

  name                = "${var.vm_name_prefix}-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
