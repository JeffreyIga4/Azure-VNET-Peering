resource azurerm_resource_group "rg" {
    name     = "peer-rg1"
    location = "canadacentral"
}

resource azurerm_virtual_network "vnet1" {
    name = "peer1"
    location = azurerm_resource_group.rg.location
    address_space = ["10.0.0.0/16"]
    resource_group_name = azurerm_resource_group.rg.name
}
