function Get-EgtInactiveUser {
    <#
    .SYNOPSIS
        Lists enabled accounts that have not signed in for a given number of days.

    .DESCRIPTION
        Reads signInActivity from Microsoft Graph. This needs AuditLog.Read.All and an
        Entra ID P1 or P2 licence in the tenant. Accounts that have never signed in are
        included when they are older than the threshold.

    .PARAMETER Days
        Inactivity threshold in days. Default is 90.

    .PARAMETER IncludeGuests
        Include guest accounts. Members only by default.

    .EXAMPLE
        Get-EgtInactiveUser -Days 60 | Export-Csv inactive-users.csv -NoTypeInformation
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 3650)]
        [int] $Days = 90,

        [switch] $IncludeGuests,

        [datetime] $Now = (Get-Date).ToUniversalTime()
    )

    $cutoff = $Now.AddDays(-$Days)
    $properties = 'id,displayName,userPrincipalName,userType,accountEnabled,createdDateTime,signInActivity'

    $users = Get-MgUser -All -Filter 'accountEnabled eq true' -Property $properties

    foreach ($user in $users) {
        if (-not $IncludeGuests -and $user.UserType -eq 'Guest') {
            continue
        }

        $lastSignIn = Get-EgtLastSignIn -SignInActivity $user.SignInActivity

        $isInactive = if ($lastSignIn) {
            $lastSignIn -lt $cutoff
        }
        else {
            $user.CreatedDateTime -and ([datetime] $user.CreatedDateTime) -lt $cutoff
        }

        if (-not $isInactive) {
            continue
        }

        [pscustomobject] @{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            UserType          = $user.UserType
            Created           = $user.CreatedDateTime
            LastSignIn        = $lastSignIn
            DaysInactive      = if ($lastSignIn) { [int] ($Now - $lastSignIn).TotalDays } else { $null }
        }
    }
}
