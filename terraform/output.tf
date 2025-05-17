
output "functionapp_url" {
  value = "https://${azurerm_linux_function_app.functionapp.name}.azurewebsites.net"
}
