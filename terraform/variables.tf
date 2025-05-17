
variable "location" {
  default = "West Europe"
}

variable "resource_group_name" {
  default = "rg-func-demo"
}

variable "storage_account_name" {
  default = "funcdemostorage" # doit être unique dans Azure !
}

variable "service_plan_name" {
  default = "asp-func-demo"
}

variable "functionapp_name" {
  default = "func-demo-12345"
}