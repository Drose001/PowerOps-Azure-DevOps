param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$ContainerAppName,

    [Parameter(Mandatory = $false)]
    [string]$TargetRevision
)

Write-Host "========================================="
Write-Host "PowerOps Rollback Automation"
Write-Host "========================================="

Write-Host ""
Write-Host "Retrieving Container App revisions..."

$revisions = az containerapp revision list `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --all `
    --query "[].{Name:name,Active:properties.active,Created:properties.createdTime}" `
    --output json | ConvertFrom-Json

if (-not $revisions) {
    throw "No revisions were found for $ContainerAppName."
}

Write-Host ""
Write-Host "Available revisions:"

$revisions |
    Sort-Object Created -Descending |
    Format-Table Name, Active, Created

if (-not $TargetRevision) {

    $activeRevisions = @(
        $revisions |
        Where-Object { $_.Active -eq $true } |
        Sort-Object Created -Descending
    )

    if ($activeRevisions.Count -lt 2) {
        throw "A previous active revision could not be identified automatically."
    }

    $currentRevision = $activeRevisions[0].Name
    $TargetRevision = $activeRevisions[1].Name

    Write-Host ""
    Write-Host "Current revision:"
    Write-Host $currentRevision

    Write-Host ""
    Write-Host "Previous stable revision selected:"
    Write-Host $TargetRevision
}

Write-Host ""
Write-Host "Activating rollback revision..."

az containerapp revision activate `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --revision $TargetRevision

if ($LASTEXITCODE -ne 0) {
    throw "Unable to activate rollback revision."
}

Write-Host ""
Write-Host "Routing 100% of traffic to:"
Write-Host $TargetRevision

az containerapp ingress traffic set `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --revision-weight "$TargetRevision=100"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to route traffic to rollback revision."
}

Write-Host ""
Write-Host "Current traffic configuration:"

az containerapp ingress traffic show `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --output table

Write-Host ""
Write-Host "========================================="
Write-Host "PowerOps rollback completed."
Write-Host "========================================="

Write-Host ""
Write-Host "Post-rollback checks:"
Write-Host "1. Verify /health returns HTTP 200"
Write-Host "2. Verify /api/sites responds successfully"
Write-Host "3. Review HTTP 500 and 503 logs"
Write-Host "4. Review response latency"
Write-Host "5. Confirm Azure Monitor alert recovery"
Write-Host "6. Document the incident and root cause"