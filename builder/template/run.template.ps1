<#
.SYNOPSIS
    Main entry point for an Azure PowerShell Function.

.DESCRIPTION
    This script serves as a generic template for Azure Functions written in PowerShell.
    It handles startup logging, execution of dynamic business logic and structured error handling.

    The `{script}` placeholder is replaced at build time with the actual user-defined logic
    for each function, based on the YAML configuration.

    Regardless of the trigger type (HTTP or Timer), the script logs start and end of execution,
    and returns a standardized response object.

.PARAMETER Request
    Represents the incoming HTTP request object for HTTP-triggered functions.
    This parameter is null for non-HTTP triggers.

.PARAMETER TriggerMetadata
    Metadata related to the function's trigger. This is automatically provided by Azure Functions
    and may contain useful context information, especially for timer-based executions.

.RETURNS
    A hashtable with the following structure:
    - status (int): HTTP-style status code (200 for success, 500 for unhandled errors)
    - body (string): A fixed success message or the error message on failure

.EXAMPLE
    # Successful response
    return @{ status = 200; body = "OK" }

    # Error response (inside catch block)
    return @{ status = 500; body = $_.Exception.Message }

.NOTES
    - This script assumes that any exceptions thrown inside the user-defined logic
      will be caught and returned with proper error reporting.
    - `Write-Information` is used for logging lifecycle events.
    - `Write-Error` captures unhandled exceptions for diagnostics.
#>

{param}

try {
    Write-Information "Function started."

    # BEGIN USER-DEFINED SCRIPT

    {script}

    # END USER-DEFINED SCRIPT

    Write-Information "Function completed successfully."
}
catch {
    Write-Error "Unhandled exception: $_"
}
