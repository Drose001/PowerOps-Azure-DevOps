param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$ContainerAppName
)

Write-Host "========================================="
Write-Host "PowerOps Canary Deployment"
Write-Host "========================================="

Write-Host ""
Write-Host "Enabling multiple revision mode..."

az containerapp revision set-mode `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --mode multiple

if ($LASTEXITCODE -ne 0) {
    throw "Unable to enable multiple revision mode."
}

Write-Host ""
Write-Host "Retrieving active PowerOps revisions..."

$revisions = az containerapp revision list `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --query "[?properties.active==\`true\`].name" `
    --output tsv

$revisionList = @(
    $revisions |
    Where-Object { $_ -and $_.Trim() -ne "" }
)

if ($revisionList.Count -lt 2) {
    throw "At least two active revisions are required for a canary deployment."
}

$stableRevision = $revisionList[-2]
$canaryRevision = $revisionList[-1]

Write-Host ""
Write-Host "Stable revision: $stableRevision"
Write-Host "Canary revision: $canaryRevision"

Write-Host ""
Write-Host "Routing traffic..."
Write-Host "Stable revision: 90%"
Write-Host "Canary revision: 10%"

az containerapp ingress traffic set `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --revision-weight `
        "$stableRevision=90" `
        "$canaryRevision=10"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to configure canary traffic."
}

Write-Host ""
Write-Host "Current traffic configuration:"

az containerapp ingress traffic show `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --output table

Write-Host ""
Write-Host "========================================="
Write-Host "Canary deployment started successfully."
Write-Host "========================================="

Write-Host ""
Write-Host "Monitor:"
Write-Host "- /health endpoint"
Write-Host "- HTTP 500 and 503 errors"13
Write-Host "- Application logs"
Write-Host "- Response times"
Write-Host "- Azure Monitor alerts"

Write-Host ""
Write-Host "PROMOTE CANARY TO 100%:"
Write-Host "az containerapp ingress traffic set --name $ContainerAppName --resource-group $ResourceGroup --revision-weight $canaryRevision=100"

Write-Host ""
Write-Host "ROLL BACK:"
Write-Host "az containerapp ingress traffic set --name $ContainerAppName --resource-group $ResourceGroup --revision-weight $stableRevision=100"