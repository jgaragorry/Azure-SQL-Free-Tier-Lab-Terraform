output "connection_string" {
  value     = "sqlcmd -S ${azurerm_mssql_server.sql.fully_qualified_domain_name} -U ${var.db_admin} -P '${random_password.sql.result}' -d ${azurerm_mssql_database.db.name}"
  sensitive = true
}

output "admin_password" {
  value      = random_password.sql.result
  sensitive  = true
}
