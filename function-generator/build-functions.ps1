<#
.SYNOPSIS
    Build script for Azure PowerShell Functions from templates and configuration.

.DESCRIPTION
    This script automates the process of generating Azure PowerShell Function Apps
    from a shared script template and a YAML configuration file.

    It performs the following steps:
    1. Imports the 'powershell-yaml' module (used to parse the YAML config).
    2. Removes any existing `./dist` directory to ensure a clean build.
    3. Recreates the `./dist` directory where the built function folders will go.
    4. Loads a script template (run.template.ps1) that contains common code.
    5. Loads the function mapping from the `function-map.yaml` configuration file.
    6. For each function defined in the YAML:
        - Reads the specific user script to embed.
        - Injects the user script into the template.
        - Creates a folder for the function in the `./dist` directory.
        - Saves the final composed script as `run.ps1` in the function folder.
        - Generates the `function.json` file that defines how the function is triggered:
            a. If a schedule is defined, it creates a timerTrigger.
            b. Otherwise, it creates an httpTrigger and adds an HTTP output.

.PARAMETERS
    None

.NOTES
    - Requires the 'powershell-yaml' module to be installed.
    - Assumes the presence of:
        • A run.template.ps1 file in the same folder as this script.
        • A function-map.yaml file one level up from this script.
        • Individual PowerShell scripts in the ./scripts/ folder.

.EXAMPLE
    PS> ./build-functions.ps1
    Will generate a set of Azure Function folders under ./dist ready to deploy.

#>

Import-Module powershell-yaml

$buildDir = "./dist"

Remove-Item -Recurse -Force $buildDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

$template = Get-Content "$PSScriptRoot/run.template.ps1" -Raw

$mapping = ConvertFrom-Yaml (Get-Content "$PSScriptRoot/../function-map.yaml" -Raw)

foreach ($fn in $mapping.functions) {
    $userScript = Get-Content "./scripts/$($fn.script)" -Raw
    $fullScript = $template -replace '\{script\}', $userScript

    $fnDir = Join-Path $buildDir $fn.name
    New-Item -ItemType Directory -Path $fnDir -Force | Out-Null
    $fullScript | Set-Content "$fnDir/run.ps1" -Encoding UTF8

    $binding = @()

    if ($fn.schedule) {
        $binding += @{
            authLevel = $fn.authLevel
            type      = "timerTrigger"
            direction = "in"
            name      = "Timer"
            schedule  = $fn.schedule
        }
    } else {
        $binding += @{
            authLevel = $fn.authLevel
            type      = "httpTrigger"
            direction = "in"
            name      = "req"
            methods   = @("get", "post")
        }

        # Add HTTP output only for HTTP trigger
        $binding += @{
            type      = "http"
            direction = "out"
            name      = "res"
        }
    }

    # We need a JSON array named bindings
    @{ bindings = $binding }
        | ConvertTo-Json -Depth 3
        | Set-Content "$fnDir/function.json" -Encoding UTF8
}
