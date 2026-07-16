locals {
  postgres_private_dns_zone_name = "privatelink.postgres.database.azure.com"
  redis_private_dns_zone_name    = "privatelink.redis.cache.windows.net"

  postgres_private_dns_zone_id = var.create_private_dns_zones ? azurerm_private_dns_zone.postgres[0].id : var.existing_postgres_private_dns_zone_id
  redis_private_dns_zone_id    = var.create_private_dns_zones ? azurerm_private_dns_zone.redis[0].id : var.existing_redis_private_dns_zone_id
}

resource "azurerm_resource_group" "paas" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_private_dns_zone" "postgres" {
  count               = var.create_private_dns_zones ? 1 : 0
  name                = local.postgres_private_dns_zone_name
  resource_group_name = azurerm_resource_group.paas.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "redis" {
  count               = var.create_private_dns_zones ? 1 : 0
  name                = local.redis_private_dns_zone_name
  resource_group_name = azurerm_resource_group.paas.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.create_private_dns_zones ? 1 : 0
  name                  = "link-${var.postgres_server_name}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  resource_group_name   = azurerm_resource_group.paas.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count                 = var.create_private_dns_zones ? 1 : 0
  name                  = "link-${var.redis_name}"
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  resource_group_name   = azurerm_resource_group.paas.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "random_password" "postgres_admin" {
  length           = 24
  special          = true
  override_special = "!#%&*()-_=+[]{}:?."
}

resource "azurerm_postgresql_flexible_server" "eic" {
  name                          = var.postgres_server_name
  resource_group_name           = azurerm_resource_group.paas.name
  location                      = azurerm_resource_group.paas.location
  version                       = var.postgres_version
  delegated_subnet_id           = var.postgres_delegated_subnet_id
  private_dns_zone_id           = local.postgres_private_dns_zone_id
  public_network_access_enabled = false

  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres_admin.result

  zone       = var.postgres_zone
  storage_mb = var.postgres_storage_mb
  sku_name   = var.postgres_sku_name

  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.postgres_ha_enabled ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = var.postgres_standby_zone
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}

resource "azurerm_postgresql_flexible_server_database" "eic" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.eic.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_redis_cache" "eic" {
  name                          = var.redis_name
  location                      = azurerm_resource_group.paas.location
  resource_group_name           = azurerm_resource_group.paas.name
  capacity                      = var.redis_capacity
  family                        = var.redis_family
  sku_name                      = var.redis_sku_name
  minimum_tls_version           = var.redis_minimum_tls_version
  public_network_access_enabled = false
  non_ssl_port_enabled          = false
  zones                         = var.redis_zones

  redis_configuration {
    maxmemory_reserved = 50
    maxmemory_delta    = 50
    maxmemory_policy   = "allkeys-lru"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "redis" {
  name                = "pe-${var.redis_name}"
  location            = azurerm_resource_group.paas.location
  resource_group_name = azurerm_resource_group.paas.name
  subnet_id           = var.redis_private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.redis_name}"
    private_connection_resource_id = azurerm_redis_cache.eic.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  private_dns_zone_group {
    name                 = "redis-dns"
    private_dns_zone_ids = [local.redis_private_dns_zone_id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.redis
  ]
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  count        = var.store_secrets_in_key_vault ? 1 : 0
  name         = "${var.postgres_server_name}-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  count = var.store_secrets_in_key_vault ? 1 : 0

  name         = "${var.redis_name}-connection-string"
  value        = "${azurerm_redis_cache.eic.hostname}:6380,password=${azurerm_redis_cache.eic.primary_access_key},ssl=True,abortConnect=False"
  key_vault_id = var.key_vault_id
}
