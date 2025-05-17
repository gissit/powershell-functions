<#
.SYNOPSIS
    Builds Azure PowerShell Functions from a shared template and per-function definitions.

.DESCRIPTION
    This script automates the generation of Azure Functions written in PowerShell using:
        - a shared execution template (`run.template.ps1`)
        - a list of function definitions described in a YAML config file (`function-map.yaml`)
        - custom user scripts stored in the `./scripts/` directory

    For each function entry, the script performs the following:
        1. Reads the corresponding script file, extracting its documentation block (if present).
        2. Removes the synopsis block from the script body to avoid duplication.
        3. Loads the common function template and replaces its synopsis block with the one from the user script.
        4. Replaces the `{script}` placeholder in the template with the properly indented body of the user script.
        5. Creates a subdirectory under `./dist/` for the function.
        6. Saves the final script as `run.ps1` inside that folder.
        7. Generates a `function.json` file defining the trigger binding:
            - If `schedule` is set: creates a `timerTrigger`.
            - Otherwise: creates an `httpTrigger` with an `http` output.

.PARAMETERS
    None

.NOTES
    Requirements:
        - The 'powershell-yaml' module must be installed.
        - `run.template.ps1` must be in the same directory as this script.
        - `function-map.yaml` must be one directory level up.
        - All referenced scripts must exist in the `./scripts/` directory.

.EXAMPLE
    PS> ./function-generator/build-functions.ps1

    This will generate a folder structure under ./dist/ with one subfolder per function,
    each containing a ready-to-deploy Azure PowerShell Function (`run.ps1`, `function.json`).

#>

Import-Module powershell-yaml

$buildDir = "./dist"

Remove-Item -Recurse -Force $buildDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

$templateDir = "$PSScriptRoot/template"
$template = Get-Content "$templateDir/run.template.ps1" -Raw

$mapping = ConvertFrom-Yaml (Get-Content "$PSScriptRoot/mapping.yaml" -Raw)

foreach ($fn in $mapping.functions) {
    $userScriptFull = Get-Content "./scripts/$($fn.script)" -Raw

    if ($userScriptFull -match '<#(.|\s)*?#>') {
        $userSynopsis = $Matches[0]
        $userScriptBody = $userScriptFull -replace [regex]::Escape($userSynopsis), '' -replace '^\s*', ''
    } else {
        $userSynopsis = ''
        $userScriptBody = $userScriptFull
    }

    $template = $template -replace '<#(.|\s)*?#>', $userSynopsis

    $indent = '    '
    $indentedScript = ($userScriptBody -split "`n" | ForEach-Object { "$indent$_" }) -join "`n"


    if ($fn.schedule) {
        $fullScript = $template -replace '\{param\}', 'param($Timer)'
    } else {
        $fullScript = $template -replace '\{param\}', 'param($Request)'
    }

    $fullScript = $fullScript -replace '\{script\}', $indentedScript.Trim()

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
            name      = "Request"
            methods   = @("get", "post")
        }

        $binding += @{
            type      = "http"
            direction = "out"
            name      = "Response"
        }
    }

    @{ bindings = $binding }
        | ConvertTo-Json -Depth 3
        | Set-Content "$fnDir/function.json" -Encoding UTF8
}

Copy-Item $templateDir/.funcignore $buildDir/.funcignore
Copy-Item $templateDir/host.json $buildDir/host.json
Copy-Item $templateDir/profile.ps1 $buildDir/profile.ps1
Copy-Item $templateDir/requirements.psd1 $buildDir/requirements.psd1
Copy-Item $templateDir/local.settings.json $buildDir/local.settings.json
