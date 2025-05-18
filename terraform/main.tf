terraform {
  backend "azurerm" {
    resource_group_name  = "rg-infra"
    storage_account_name = "stgissitinfra"
    container_name       = "tfstate"
    key                  = "powershell-functions/dev.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  storage_use_azuread = true
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  shared_access_key_enabled = false
}

resource "azurerm_service_plan" "asp" {
  name                = var.service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "functionapp" {
  name                = var.functionapp_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id
  storage_account_name = azurerm_storage_account.sa.name
  storage_uses_managed_identity = true
  https_only          = true

  site_config {
    application_stack {
      powershell_core_version = "7.4"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "powershell"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_role_assignment" "func_to_storage" {
  principal_id         = azurerm_linux_function_app.func.identity.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.main.id
}
