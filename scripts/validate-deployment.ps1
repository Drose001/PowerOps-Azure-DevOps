param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

Write-Host "========================================="
Write-Host "PowerOps Deployment Validation"
Write-Host "========================================="

$BaseUrl = $BaseUrl.TrimEnd('/')

$checks = @(
    @{
        Name = "Application Status"
        Url  = "$BaseUrl/"
    },
    @{
        Name = "Health Check"
        Url  = "$BaseUrl/health"
    },
    @{
        Name = "Energy Sites API"
        Url  = "$BaseUrl/api/sites"
    }
)

$failed = $false

foreach ($check in $checks) {

    Write-Host ""
    Write-Host "Testing: $($check.Name)"
    Write-Host "URL: $($check.Url)"

    try {

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        $response = Invoke-WebRequest `
            -Uri $check.Url `
            -Method GET `
            -UseBasicParsing `
            -TimeoutSec 30

        $stopwatch.Stop()

        Write-Host "Status Code: $($response.StatusCode)"
        Write-Host "Response Time: $($stopwatch.ElapsedMilliseconds) ms"

        if ($response.StatusCode -ne 200) {
            Write-Host "FAILED: Expected HTTP 200."
            $failed = $true
        }
        else {
            Write-Host "PASSED"
        }

    }
    catch {

        Write-Host "FAILED"
        Write-Host $_.Exception.Message

        $failed = $true
    }
}

Write-Host ""
Write-Host "========================================="

if ($failed) {

    Write-Host "DEPLOYMENT VALIDATION FAILED"
    Write-Host "The release should NOT be promoted."

    exit 1
}

Write-Host "DEPLOYMENT VALIDATION PASSED"
Write-Host "PowerOps is healthy and ready for promotion."

Write-Host "========================================="

exit 0