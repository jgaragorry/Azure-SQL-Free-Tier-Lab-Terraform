###########################
# Terraform & Providers
###########################
terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

############################################
# 0️⃣ Instala sqlcmd localmente si no existe
############################################

resource "null_resource" "install_sqlcmd" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      if ! command -v sqlcmd >/dev/null 2>&1; then
        echo "🔧 Instalando sqlcmd (Go)…"
        VER="1.8.2"
        ASSET="sqlcmd-linux-amd64.tar.bz2"
        URL="https://github.com/microsoft/go-sqlcmd/releases/download/v$${VER}/$${ASSET}"
        TMP="/tmp/$${ASSET}"

        echo "➡️  Descargando $${URL}"
        curl -fSL "$${URL}" -o "$${TMP}"
        file "$${TMP}" | grep -q 'bzip2 compressed'   # aborta si no es bzip2
        tar -xjf "$${TMP}"
        chmod +x sqlcmd
        mkdir -p "$HOME/.local/bin"
        mv sqlcmd "$HOME/.local/bin/"

        echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.profile"
        echo "✅ sqlcmd instalado en ~/.local/bin"
      else
        echo "✅ sqlcmd ya presente"
      fi
    EOT
  }
}


########################
# 1️⃣ Infra Azure básica
########################
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags_common
}

resource "random_password" "sql" {
  length  = 16
  special = true
}

resource "azurerm_mssql_server" "sql" {
  name                          = "${var.resource_prefix}-sqlsrv"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = var.db_admin
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags                          = var.tags_common
}

resource "azurerm_mssql_database" "db" {
  name      = "${var.resource_prefix}-db"
  server_id = azurerm_mssql_server.sql.id

  # Serverless, 2 vCores máx (FREE tier)
  sku_name                    = "GP_S_Gen5_2"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60

  tags = merge(var.tags_common, { tier = "free" })
}

data "http" "myip" { url = "https://ifconfig.me/ip" }

resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "allow-my-ip"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = chomp(data.http.myip.response_body)
  end_ip_address   = chomp(data.http.myip.response_body)
}

#####################################
# 2️⃣ Smoke-test de conectividad
#####################################
resource "null_resource" "smoke_test" {
  depends_on = [
    azurerm_mssql_database.db,
    null_resource.install_sqlcmd
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      # Añadimos ~/.local/bin al PATH para este proceso
      PATH="$HOME/.local/bin:$PATH"

      "$HOME/.local/bin/sqlcmd" \
        -S ${azurerm_mssql_server.sql.fully_qualified_domain_name} \
        -U ${var.db_admin} -P '${random_password.sql.result}' \
        -d ${azurerm_mssql_database.db.name} \
        -Q "SELECT GETDATE() AS deployed_at;" \
        -b -r 0
    EOT
  }
}
