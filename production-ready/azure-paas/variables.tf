variable "resource_group_name" {
  description = "Name of the resource group for Azure PaaS resources."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "create_private_dns_zones" {
  description = "Create private DNS zones for PostgreSQL and Redis in this module."
  type        = bool
  default     = true
}

variable "vnet_id" {
  description = "Virtual network ID used to link private DNS zones. Required when create_private_dns_zones is true."
  type        = string
  default     = null
}

variable "existing_postgres_private_dns_zone_id" {
  description = "Existing private DNS zone ID for PostgreSQL (privatelink.postgres.database.azure.com). Used when create_private_dns_zones is false."
  type        = string
  default     = null
}

variable "existing_redis_private_dns_zone_id" {
  description = "Existing private DNS zone ID for Redis (privatelink.redis.cache.windows.net). Used when create_private_dns_zones is false."
  type        = string
  default     = null
}

variable "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server."
  type        = string
}

variable "postgres_database_name" {
  description = "Name of the EIC database created on PostgreSQL."
  type        = string
  default     = "eic"
}

variable "postgres_admin_username" {
  description = "Admin username for PostgreSQL Flexible Server."
  type        = string
  default     = "pgadmin"
}

variable "postgres_sku_name" {
  description = "SKU name for PostgreSQL Flexible Server (for example GP_Standard_D2s_v3)."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "Allocated storage in MB for PostgreSQL Flexible Server."
  type        = number
  default     = 131072
}

variable "postgres_backup_retention_days" {
  description = "Backup retention in days for PostgreSQL Flexible Server."
  type        = number
  default     = 14

  validation {
    condition     = var.postgres_backup_retention_days >= 7 && var.postgres_backup_retention_days <= 35
    error_message = "postgres_backup_retention_days must be between 7 and 35."
  }
}

variable "postgres_geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups for PostgreSQL Flexible Server."
  type        = bool
  default     = false
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "postgres_zone" {
  description = "Primary availability zone for PostgreSQL Flexible Server."
  type        = string
  default     = "1"
}

variable "postgres_standby_zone" {
  description = "Standby availability zone used when zone-redundant HA is enabled."
  type        = string
  default     = "2"
}

variable "postgres_ha_enabled" {
  description = "Enable zone-redundant high availability for PostgreSQL Flexible Server."
  type        = bool
  default     = true
}

variable "postgres_delegated_subnet_id" {
  description = "Delegated subnet ID for PostgreSQL Flexible Server private access. Subnet must be delegated to Microsoft.DBforPostgreSQL/flexibleServers."
  type        = string
}

variable "redis_name" {
  description = "Name of the Azure Managed Redis cache instance."
  type        = string
}

variable "redis_sku_name" {
  description = "Redis SKU name."
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_sku_name)
    error_message = "redis_sku_name must be one of: Basic, Standard, Premium."
  }
}

variable "redis_family" {
  description = "Redis family (C for Basic/Standard, P for Premium)."
  type        = string
  default     = "P"
}

variable "redis_capacity" {
  description = "Redis capacity depending on family/SKU."
  type        = number
  default     = 1
}

variable "redis_minimum_tls_version" {
  description = "Minimum TLS version for Redis."
  type        = string
  default     = "1.2"
}

variable "redis_private_endpoint_subnet_id" {
  description = "Subnet ID used for Redis private endpoint."
  type        = string
}

variable "redis_zones" {
  description = "Availability zones for Redis where supported by region/SKU."
  type        = list(string)
  default     = []
}

variable "store_secrets_in_key_vault" {
  description = "Store generated PostgreSQL admin password and Redis connection string in Key Vault."
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = "Target Key Vault ID for secrets. Required when store_secrets_in_key_vault is true."
  type        = string
  default     = null
}
