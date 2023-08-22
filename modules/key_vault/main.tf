# This policy must be kept for a proper run of the "destroy" process
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