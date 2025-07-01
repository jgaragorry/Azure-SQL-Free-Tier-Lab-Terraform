# ☁️ Azure SQL Free‑Tier Lab – Terraform, FinOps & Security‑First

Laboratorio automatizado para desplegar, verificar y eliminar una **Azure SQL Database Serverless – Free Tier** usando **Terraform 1.7+** y **Azure CLI**. Integra buenas prácticas de **FinOps**, **gobernanza**, **seguridad** y **etiquetado** para laboratorios, entornos de prueba o capacitación.

---

## 🎯 Objetivo

> Al finalizar aprenderás a:

- Preparar un entorno WSL con Ubuntu Server 24.04 LTS.
- Desplegar infraestructura de bajo costo en Azure usando Terraform.
- Aplicar etiquetas (tags) padronizadas para gestión de costes.
- Proteger la superficie de ataque (TLS 1.2 y reglas de firewall just‑in‑time).
- Verificar conectividad SQL y eliminar recursos, evitando cargos.

---

## 📋 Índice

- [Arquitectura](#arquitectura)
- [Requisitos previos](#requisitos-previos)
- [Instalación de herramientas](#instalación-de-herramientas)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Despliegue paso a paso](#despliegue-paso-a-paso)
- [Verificación](#verificación)
- [Destrucción y limpieza](#destrucción-y-limpieza)
- [Buenas prácticas FinOps](#buenas-prácticas-finops)
- [Seguridad y gobernanza](#seguridad-y-gobernanza)
- [Solución de problemas](#solución-de-problemas)
- [Referencias](#referencias)

---

## 🧱 Arquitectura

```
┌────────────────────────────────────────┐
│         Azure Resource Group           │ «labdb-rg» (East US 2)
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ Azure SQL Logical Server         │  │ «labdb-sqlsrv»
│  │  • TLS 1.2                       │  │
│  │  • Public network (scoped IP)    │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Azure SQL Database (serverless)  │  │ «labdb-db» – Free Tier
│  │  • 0.5–2 vCore (auto‑pause 60 m) │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

- 🌎 **Región:** `eastus2`
- 💸 **Modelo:** serverless con auto-pausa → paga solo por uso
- 🔐 **Acceso:** solo desde tu IP pública al momento del despliegue

---

## 🔧 Requisitos Previos

| Herramienta    | Versión mínima | Instalado en       |
|----------------|----------------|---------------------|
| Ubuntu (WSL)   | 24.04 LTS      | Windows 10/11       |
| Azure CLI      | 2.60           | WSL                 |
| Terraform      | 1.7            | WSL                 |
| sqlcmd         | ≥ 1.8          | WSL (auto-instalado)|

📌 Validado en Windows 11 + WSL 2

---

## ⚙️ Instalación de Herramientas

### Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Terraform

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

### Verificación

```bash
az version | jq '.azure-cli'
terraform -version
```

---

## 📁 Estructura del Proyecto

```
terraform-sql/
├── main.tf
├── variables.tf
├── outputs.tf
├── NOTICE.md
└── sqlcmd_debug/
```

### Archivos clave

| Archivo        | Descripción                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `main.tf`      | Proveedor, RG, SQL Server y DB, IP Firewall, prueba sqlcmd                  |
| `variables.tf` | Parámetros: región, tags, usuario, nombres                                  |
| `outputs.tf`   | Muestra connection string y contraseña generada (ocultas por seguridad)     |

### Etiquetas por defecto

```hcl
environment  = "lab"
cost_center  = "demo"
owner        = "tu.email@dominio.com"
project      = "azure-sql-free-tier-lab"
delete_after = "2025-07-01T23:59:00Z"
```

---

## 🚀 Despliegue Paso a Paso

```bash
git clone https://github.com/<TU-USUARIO>/terraform-sql.git
cd terraform-sql

az login --use-device-code
az account set --subscription "<TU-SUBSCRIPCIÓN>"

terraform init
terraform plan -out tfplan
terraform apply tfplan
```

- 🧠 `sqlcmd` se descarga (~10MB) y se ubica en `~/.local/bin`
- 🔐 Contraseña SQL se genera aleatoriamente y se almacena en el *state*

---

## ✅ Verificación

### 1. Recupera la contraseña

```bash
terraform output -raw admin_password
```

### 2. Ejecuta el test SQL

```bash
sqlcmd -S <FQDN> -U sqladmin -P '<PASSWORD>' -d labdb-db -Q "SELECT @@VERSION, '$(date)' AS local_time;"
```

🧪 Esto devuelve:
- La versión del motor de Azure SQL (`@@VERSION`)
- La hora local de tu sistema (`$(date)`)

Útil para validar conectividad y estimar latencia.

---

## 🧹 Destrucción y Limpieza

```bash
terraform destroy -auto-approve
```

💡 Consejo FinOps: automatiza con GitHub Actions o configura Azure Auto-Shutdown.

---

## 💰 Buenas Prácticas FinOps

| Práctica            | Implementación                                         |
|---------------------|--------------------------------------------------------|
| Capas gratuitas     | Tier serverless con auto-pause                        |
| Etiquetado estándar | Tags heredados en todos los recursos                  |
| Apagado automático  | SQL se "pausa" tras 60 min inactivo                   |
| Región optimizada   | `eastus2`: económico y habilitado para Free Tier      |
| Infra mínima        | Solo un RG, servidor y base de datos                  |

---

## 🔐 Seguridad y Gobernanza

- 🔒 **TLS 1.2** forzado en el servidor
- 🌍 **Firewall** habilitado solo para tu IP actual
- 🧩 **Contraseña aleatoria** generada y marcada como `sensitive`
- 🧑‍💻 **Principio de mínimo privilegio**: solo autenticación SQL local

---

## 🛠️ Solución de Problemas

| Síntoma                               | Causa              | Acción                                  |
|---------------------------------------|---------------------|------------------------------------------|
| `sqlcmd` error ODBC                   | IP pública cambió   | Reaplica el plan con tu nueva IP         |
| `terraform init` falla                | Proxy corporativo   | Exporta `HTTPS_PROXY`                    |
| `sqlcmd` no se instala                | Falta curl o tar    | `sudo apt-get install curl tar bzip2`    |

---

## 📚 Referencias

- [Azure SQL Free Tier](https://learn.microsoft.com/azure/azure-sql/database/free)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [FinOps Foundation – Azure](https://www.finops.org/community/azure)
- [Security Baseline – Azure SQL](https://learn.microsoft.com/azure/azure-sql/database/security-baseline)

---

## 📜 Licencia

Publicado bajo licencia MIT. Consulta `NOTICE.md` para más información.

---

⌛ **Duración estimada:**  
🧰 Herramientas: ~10 min  
🚀 Despliegue: ~3 min  
✅ Verificación: ~1 min

---

¡Feliz automatización! 🎉
