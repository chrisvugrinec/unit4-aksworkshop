resource "azurerm_resource_group" "tftest" {
  name     = "vuggie-acr-rg"
  location = "westeurope"
}

resource "azurerm_container_registry" "tftest" {
  name                = "vuggieacr"
  resource_group_name = "${azurerm_resource_group.tftest.name}"
  location            = "${azurerm_resource_group.tftest.location}"
  admin_enabled       = true
  sku                 = "Basic"
}
