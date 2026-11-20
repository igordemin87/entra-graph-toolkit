function Get-EgtGroupAudit {
    <#
    .SYNOPSIS
        Finds groups with no owners or no members.

    .DESCRIPTION
        Makes one owner call and one member-count call per group, so large tenants take a while.
        Use -Filter to narrow the scope, for example to security groups only.

    .PARAMETER Filter
        OData filter passed to Get-MgGroup.

    .EXAMPLE
        Get-EgtGroupAudit | Where-Object { $_.Issues } | Export-Csv group-audit.csv -NoTypeInformation

    .EXAMPLE
        Get-EgtGroupAudit -Filter "securityEnabled eq true and mailEnabled eq false"
    #>
    [CmdletBinding()]
    param(
        [string] $Filter
    )

    $params = @{
        All      = $true
        Property = 'id,displayName,groupTypes,securityEnabled,mailEnabled,createdDateTime'
    }
    if ($Filter) {
        $params.Filter = $Filter
    }

    foreach ($group in Get-MgGroup @params) {
        $owners  = @(Get-MgGroupOwner -GroupId $group.Id -All)
        $members = [int] (Get-MgGroupMemberCount -GroupId $group.Id -ConsistencyLevel eventual)

        $issues = @()
        if ($owners.Count -eq 0) { $issues += 'NoOwners' }
        if ($members -eq 0)      { $issues += 'NoMembers' }

        $kind = if ($group.GroupTypes -contains 'Unified') {
            'Microsoft365'
        }
        elseif ($group.SecurityEnabled -and -not $group.MailEnabled) {
            'Security'
        }
        else {
            'Other'
        }

        [pscustomobject] @{
            DisplayName = $group.DisplayName
            Id          = $group.Id
            Kind        = $kind
            Owners      = $owners.Count
            Members     = $members
            Created     = $group.CreatedDateTime
            Issues      = $issues -join ','
        }
    }
}
