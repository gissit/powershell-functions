# Bazar Function Framework Wrapper v1.0

param($Request, $TriggerMetadata)

try {
    Write-Information "Function started."

{script}

    Write-Information "Function completed successfully."
    return @{ status = 200; body = "OK" }
}
catch {
    Write-Error "Unhandled exception: $_"
    return @{ status = 500; body = $_.Exception.Message }
}
