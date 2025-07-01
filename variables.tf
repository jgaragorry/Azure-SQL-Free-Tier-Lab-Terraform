variable "location" {
  description = "Región Azure"
  default     = "eastus2"
}

variable "resource_prefix" {
  description = "Prefijo recursos"
  default     = "labdb"
}

variable "db_admin" {
  description = "Usuario admin SQL"
  default     = "sqladmin"
}

variable "db_password" {
  description = "Password admin"
  type        = string
}

variable "tags_common" {
  description = "Etiquetas FinOps"
  type        = map(string)
  default = {
    environment  = "lab"
    cost_center  = "demo"
    owner        = "tu.email@dominio.com"
    project      = "azure-sql-free-tier-lab"
    delete_after = "2025-07-01T23:59:00Z"
  }
}
