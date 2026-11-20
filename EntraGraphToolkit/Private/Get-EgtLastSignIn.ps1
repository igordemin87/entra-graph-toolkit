function Get-EgtLastSignIn {
    <#
    .SYNOPSIS
        Returns the most recent sign-in time from a Graph signInActivity object, or $null.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter()]
        [AllowNull()]
        [object] $SignInActivity
    )

    if ($null -eq $SignInActivity) {
        return $null
    }

    $candidates = foreach ($name in 'LastSuccessfulSignInDateTime', 'LastSignInDateTime', 'LastNonInteractiveSignInDateTime') {
        $property = $SignInActivity.PSObject.Properties[$name]
        if ($property -and $property.Value) {
            [datetime] $property.Value
        }
    }

    if (-not $candidates) {
        return $null
    }

    return ($candidates | Sort-Object -Descending | Select-Object -First 1)
}
