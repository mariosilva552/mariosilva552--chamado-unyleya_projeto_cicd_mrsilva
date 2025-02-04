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
  name                = "devopsmrsilva"
  resource_group_name = azurerm_resource_group.producao.name
  location            = azurerm_resource_group.producao.location
  service_plan_id     = azurerm_service_plan.producao.id

  depends_on = [azurerm_service_plan.producao, azurerm_resource_group.producao]

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# Criar um IP Público gratuito para produção
resource "azurerm_public_ip" "producao" {
  name                = "producao-public-ip"
  resource_group_name = azurerm_resource_group.producao.name
  location            = azurerm_resource_group.producao.location
  allocation_method   = "Dynamic"  # Gratuito apenas no modo dinâmico
  sku                 = "Basic"    # Gratuito apenas no SKU Básico
}

# Criar um Application Gateway para expor o App Service com o IP Público
resource "azurerm_application_gateway" "producao" {
  name                = "producao-app-gateway"
  resource_group_name = azurerm_resource_group.producao.name
  location            = azurerm_resource_group.producao.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.producao.id  # Necessário criar uma sub-rede
  }

  frontend_ip_configuration {
    name                 = "public-ip-frontend"
    public_ip_address_id = azurerm_public_ip.producao.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-ip-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-backend"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-backend"
  }
}

# Criar saídas para exibir as URLs dos App Services e o IP público
output "desenvolvimento_app_service_url" {
  value = azurerm_linux_web_app.desenvolvimento.default_hostname
}

output "producao_app_service_url" {
  value = azurerm_linux_web_app.producao.default_hostname
}

output "producao_public_ip" {
  value = azurerm_public_ip.producao.ip_address
}
