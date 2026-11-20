function Connect-EgtGraph {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph with the read-only scopes this module needs.

    .DESCRIPTION
        Uses delegated sign-in by default. For unattended runs, pass -ClientId, -TenantId and
        -CertificateThumbprint of an app registration that has the same application permissions.

    .EXAMPLE
        Connect-EgtGraph

    .EXAMPLE
        Connect-EgtGraph -TenantId $tenantId -ClientId $appId -CertificateThumbprint $thumbprint
    #>
    [CmdletBinding(DefaultParameterSetName = 'Delegated')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'App')]
        [string] $TenantId,

        [Parameter(Mandatory, ParameterSetName = 'App')]
        [string] $ClientId,

        [Parameter(Mandatory, ParameterSetName = 'App')]
        [string] $CertificateThumbprint
    )

    $scopes = @(
        'User.Read.All'
        'AuditLog.Read.All'
        'Group.Read.All'
        'GroupMember.Read.All'
        'Organization.Read.All'
    )

    if ($PSCmdlet.ParameterSetName -eq 'App') {
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
    }
    else {
        Connect-MgGraph -Scopes $scopes -NoWelcome
    }
}
