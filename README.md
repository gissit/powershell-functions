# PowerShell in Azure Functions

[Azure Functions PowerShell developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)

[Create a PowerShell function in Azure using Visual Studio Code](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell)

```
terraform init

az login

$SubscriptionId = az account show --query id -o tsv
$env:ARM_SUBSCRIPTION_ID = $SubscriptionId

terraform plan
terraform apply
```

[Azure resources](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureresourcegroups)

[Azurite extension](https://marketplace.visualstudio.com/items?itemName=Azurite.azurite)

[Azure tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)

