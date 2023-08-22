resource "azurerm_storage_account" "vmlyswgcstorage" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "example" {
  name                  = var.ctname
  storage_account_name  = azurerm_storage_account.vmlyswgcstorage.name
  container_access_type = "private"
}