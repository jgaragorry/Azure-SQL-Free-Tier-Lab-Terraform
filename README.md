# ☁️ Azure SQL Free‑Tier Lab – Terraform, FinOps & Security‑First

Automatiza el despliegue, verificación y limpieza de una base de datos **Azure SQL Database Serverless – Free Tier** con **Terraform 1.7+**, siguiendo buenas prácticas de FinOps, gobernanza y seguridad.

---

## 🎯 Objetivo

> Al finalizar este laboratorio, aprenderás a:

- Preparar un entorno WSL Ubuntu Server 24.04 LTS listo para usar.
- Implementar infraestructura de bajo costo en Azure con Terraform.
- Aplicar etiquetas estándar (tags) para gestión de costes.
- Proteger con TLS 1.2 y firewall Just-in-Time.
- Verificar la conectividad con `sqlcmd`.
- Destruir todo y evitar costos innecesarios.

---

## 🗂️ Índice Rápido

- [🧱 Arquitectura](#-arquitectura)
- [🔧 Requisitos previos](#-requisitos-previos)
- [⚙️ Instalación de herramientas](#-instalación-de-herramientas)
- [📁 Estructura del proyecto](#-estructura-del-proyecto)
- [🚀 Despliegue paso a paso](#-despliegue-paso-a-paso)
- [✅ Verificación](#-verificación)
- [🧹 Destrucción y limpieza](#-destrucción-y-limpieza)
- [💰 Buenas prácticas FinOps](#-buenas-prácticas-finops)
- [🔐 Seguridad y gobernanza](#-seguridad-y-gobernanza)
- [🛠️ Solución de problemas](#-solución-de-problemas)
- [📚 Referencias](#-referencias)

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

- 📍 **Región:** `eastus2` (admite free tier con alta disponibilidad)
- 💡 **Consumo:** solo se cobra cuando está en uso (serverless + autopause)
- 🔒 **Acceso:** se restringe a la IP pública al momento de despliegue

---

## 🔧 Requisitos Previos

| Herramienta     | Versión mínima | Instalado en        |
|------------------|----------------|----------------------|
| Ubuntu (WSL)     | 24.04 LTS      | Windows 10/11        |
| Azure CLI        | 2.60           | WSL                  |
| Terraform        | 1.7            | WSL                  |
| sqlcmd           | ≥ 1.8          | WSL (se auto-instala)|

ℹ️ Validado en Windows 11 + WSL 2 con Ubuntu 24.04

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
├── main.tf          # Recursos y pruebas
├── variables.tf     # Parámetros reutilizables
├── outputs.tf       # Conexión y secretos sensibles
├── NOTICE.md        # Licencia
└── sqlcmd_debug/    # (opcional) trazas sqlcmd
```

### 🧩 Contenidos clave

- `main.tf`: proveedor, sqlcmd, resource group, servidor, BD, firewall y test
- `variables.tf`: location, tags, usuarios
- `outputs.tf`: connection string y contraseña (`sensitive = true`)

---

## 🚀 Despliegue Paso a Paso

1. Clona el repo:

```bash
git clone https://github.com/<TU-USUARIO>/terraform-sql.git
cd terraform-sql
```

2. Autenticación con Azure:

```bash
az login --use-device-code
az account set --subscription "<TU-SUBSCRIPCIÓN>"
```

3. Inicializa y aplica:

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

✅ Genera contraseña aleatoria  
✅ sqlcmd se descarga en `~/.local/bin`

---

## ✅ Verificación

Ejecuta el comando mostrado en los outputs:

```bash
sqlcmd -S <FQDN> -U sqladmin -P '<PASSWORD>' -d labdb-db -Q "SELECT @@VERSION, '$(date)' AS local_time;"
```

Deberías ver el resultado de la consulta con la hora actual UTC.

---

## 🧹 Destrucción y Limpieza

```bash
terraform destroy -auto-approve
```

💡 Consejo FinOps: automatiza limpieza con GitHub Actions o usa **Azure Auto-Shutdown**.

---

## 💰 Buenas Prácticas FinOps

| Práctica             | Aplicación                                                        |
|----------------------|--------------------------------------------------------------------|
| Capas gratuitas      | `GP_S_Gen5_2` + auto-pause = coste cercano a cero                 |
| Etiquetado estándar  | `owner`, `project`, `cost_center`, `delete_after`, etc.           |
| Autoapagado          | Pausa tras 60 min inactivo                                        |
| Región optimizada    | `eastus2` (tarifas competitivas + admite tier gratuito)           |
| Infra mínima         | 1 resource group + 2 recursos SQL                                 |

---

## 🔐 Seguridad y Gobernanza

- TLS 1.2 forzado en el servidor
- Firewall limitado a tu IP (`azurerm_mssql_firewall_rule`)
- Contraseña segura generada y protegida (`random_password`)
- Sin roles adicionales: mínimo privilegio

---

## 🛠️ Solución de Problemas

| Síntoma                          | Causa                   | Acción                                  |
|----------------------------------|--------------------------|------------------------------------------|
| `sqlcmd` ODBC error              | TLS o puerto bloqueado  | Verifica IP pública + vuelve a aplicar  |
| `terraform init` falla          | Proxy corporativo       | Exporta `HTTPS_PROXY`                   |
| sqlcmd no se instala             | Faltan paquetes base    | Instala `curl`, `tar`, `bzip2`          |

---

## 📚 Referencias

- [Azure SQL Free Tier](https://learn.microsoft.com/azure/azure-sql/database/free)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [FinOps Foundation – Azure](https://www.finops.org/community/azure)
- [Security Baseline – Azure SQL](https://learn.microsoft.com/azure/azure-sql/database/security-baseline)

---

## 📜 Licencia

Publicado bajo licencia **MIT**. Consulta `NOTICE.md` para más información.

---

⌛ **Duración total:**  
🛠️ Instalación: ~10 min  
🚀 Despliegue: ~3 min  
✅ Prueba: ~1 min

---

¡Feliz automatización! 🎉
