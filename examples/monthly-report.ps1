# Builds three CSV reports in ./reports. Run after Connect-EgtGraph.
Import-Module (Join-Path $PSScriptRoot '..' 'EntraGraphToolkit') -Force

$out = Join-Path $PSScriptRoot 'reports'
New-Item -ItemType Directory -Path $out -Force | Out-Null

Get-EgtInactiveUser -Days 90 |
    Export-Csv (Join-Path $out 'inactive-users.csv') -NoTypeInformation

Get-EgtLicenseSummary |
    Sort-Object Free -Descending |
    Export-Csv (Join-Path $out 'licenses.csv') -NoTypeInformation

Get-EgtGroupAudit -Filter 'securityEnabled eq true' |
    Where-Object Issues |
    Export-Csv (Join-Path $out 'group-issues.csv') -NoTypeInformation

Write-Host "Reports written to $out"
