terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Configuração do Provider Azure
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Criar Resource Groups para os dois ambientes
resource "azurerm_resource_group" "desenvolvimento" {
  name     = "desenvolvimento-dev-rg"
  location = "West Europe"
}

resource "azurerm_resource_group" "producao" {
  name     = "producao-app-rg"
  location = "West Europe"
}

# Criar um Service Plan para cada ambiente
resource "azurerm_service_plan" "desenvolvimento" {
  name                = "desenvolvimento-dev-service-plan"
  resource_group_name = azurerm_resource_group.desenvolvimento.name
  location            = azurerm_resource_group.desenvolvimento.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_service_plan" "producao" {
  name                = "producao-app-service-plan"
  resource_group_name = azurerm_resource_group.producao.name
  location            = azurerm_resource_group.producao.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# Criar os App Services para cada ambiente com os nomes corretos
resource "azurerm_linux_web_app" "desenvolvimento" {
  name                = "desenvolvimento-dev"
  resource_group_name = azurerm_resource_group.desenvolvimento.name
  location            = azurerm_resource_group.desenvolvimento.location
  service_plan_id     = azurerm_service_plan.desenvolvimento.id

  depends_on = [azurerm_service_plan.desenvolvimento]

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_linux_web_app" "producao" {
  name                = "devopsmrsilva" # 🔹 Alterado para corresponder ao nome esperado no erro do Azure DevOps
  resource_group_name = azurerm_resource_group.producao.name
  location            = azurerm_resource_group.producao.location
  service_plan_id     = azurerm_service_plan.producao.id

  depends_on = [azurerm_service_plan.producao, azurerm_resource_group.producao] # 🔹 Garantir que esses recursos existam antes

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# Criar saídas para exibir as URLs dos App Services
output "desenvolvimento_app_service_url" {
  value = azurerm_linux_web_app.desenvolvimento.default_hostname
}

output "producao_app_service_url" {
  value = azurerm_linux_web_app.producao.default_hostname
}