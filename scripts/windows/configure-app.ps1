$ErrorActionPreference = "Stop"

Write-Output "Installing IIS..."
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

Import-Module WebAdministration

$SiteName = "Default Web Site"
$Port = 8443
$FirewallRule = "Lab-Allow-App-TCP-8443"

Write-Output "Creating the application test page..."

@"
<!DOCTYPE html>
<html>
<head>
    <title>Application Tier</title>
</head>
<body>
    <h1>Application Tier</h1>
    <p>Server: $env:COMPUTERNAME</p>
    <p>TCP port: 8443</p>
    <p>The web tier successfully reached the application tier.</p>
</body>
</html>
"@ | Set-Content `
    -Path "C:\inetpub\wwwroot\index.html" `
    -Encoding UTF8

$ExistingBinding = Get-WebBinding `
    -Name $SiteName `
    -Protocol "http" |
    Where-Object {
        $_.bindingInformation -eq "*:${Port}:"
    }

if (-not $ExistingBinding) {
    Write-Output "Creating IIS binding on TCP port $Port..."

    New-WebBinding `
        -Name $SiteName `
        -Protocol "http" `
        -IPAddress "*" `
        -Port $Port
}
else {
    Write-Output "IIS binding already exists."
}

$ExistingFirewallRule = Get-NetFirewallRule `
    -DisplayName $FirewallRule `
    -ErrorAction SilentlyContinue

if (-not $ExistingFirewallRule) {
    Write-Output "Creating Windows Firewall rule..."

    New-NetFirewallRule `
        -DisplayName $FirewallRule `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $Port `
        -RemoteAddress "10.30.0.0/16" `
        -Action Allow
}
else {
    Write-Output "Windows Firewall rule already exists."
}

Set-Service -Name W3SVC -StartupType Automatic
Start-Service -Name W3SVC
Start-WebSite -Name $SiteName

Write-Output "Testing the local application listener..."

$response = Invoke-WebRequest `
    -Uri "http://localhost:$Port/" `
    -UseBasicParsing `
    -TimeoutSec 5

Write-Output "HTTP status: $($response.StatusCode)"
Write-Output "Application listener configuration completed."