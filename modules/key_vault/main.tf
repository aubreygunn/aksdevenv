# This policy must be kept for a proper run of the "destroy" process

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# Create the Azure Key Vault
resource "azurerm_key_vault" "key_vault" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  tenant_id = data.azuread_client_config.current.tenant_id
  sku_name  = var.sku_name

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_access_policy" "default_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id
  key_permissions         = ["get", "create", "delete", "purge", "recover", "update", "list"]
  secret_permissions      = ["delete", "get", "set", "list"]
  certificate_permissions = var.kv-certificate-permissions-full
  storage_permissions     = var.kv-storage-permissions-full

  lifecycle {
    create_before_destroy = true
  }
}