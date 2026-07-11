output "resource_group_name" {
  description = "Resource group containing PostgreSQL and Redis resources."
  value       = azurerm_resource_group.paas.name
}

output "postgres_server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.eic.id
}

output "postgres_fqdn" {
  description = "Private FQDN of PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.eic.fqdn
}

output "postgres_database_name" {
  description = "Created PostgreSQL database name for EIC."
  value       = azurerm_postgresql_flexible_server_database.eic.name
}

output "postgres_admin_username" {
  description = "Admin username for PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.eic.administrator_login
}

output "postgres_admin_password" {
  description = "Generated PostgreSQL admin password."
  value       = random_password.postgres_admin.result
  sensitive   = true
}

output "redis_id" {
  description = "Resource ID of Redis cache."
  value       = azurerm_redis_cache.eic.id
}

output "redis_hostname" {
  description = "Redis hostname."
  value       = azurerm_redis_cache.eic.hostname
}

output "redis_ssl_port" {
  description = "Redis SSL port."
  value       = azurerm_redis_cache.eic.ssl_port
}

output "redis_primary_access_key" {
  description = "Redis primary access key."
  value       = azurerm_redis_cache.eic.primary_access_key
  sensitive   = true
}

output "redis_private_endpoint_ip" {
  description = "Redis private endpoint IP address."
  value       = azurerm_private_endpoint.redis.private_service_connection[0].private_ip_address
}

output "postgres_private_dns_zone_id" {
  description = "Private DNS zone ID used by PostgreSQL."
  value       = local.postgres_private_dns_zone_id
}

output "redis_private_dns_zone_id" {
  description = "Private DNS zone ID used by Redis."
  value       = local.redis_private_dns_zone_id
}
