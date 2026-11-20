BeforeAll {
    $moduleRoot = Join-Path $PSScriptRoot '..' 'EntraGraphToolkit'
    Get-ChildItem (Join-Path $moduleRoot 'Private'), (Join-Path $moduleRoot 'Public') -Filter '*.ps1' |
        ForEach-Object { . $_.FullName }

    # Stubs so the tests run without the Microsoft.Graph modules or a tenant.
    function Get-MgUser { param([switch] $All, [string] $Filter, [string[]] $Property) }
    function Get-MgSubscribedSku { param([switch] $All) }
    function Get-MgGroup { param([switch] $All, [string] $Filter, [string[]] $Property) }
    function Get-MgGroupOwner { param([string] $GroupId, [switch] $All) }
    function Get-MgGroupMemberCount { param([string] $GroupId, [string] $ConsistencyLevel) }
}

Describe 'Get-EgtLastSignIn' {
    It 'returns null when there is no sign-in activity' {
        Get-EgtLastSignIn -SignInActivity $null | Should -BeNullOrEmpty
    }

    It 'returns the latest of the available timestamps' {
        $activity = [pscustomobject] @{
            LastSignInDateTime               = [datetime] '2026-01-10'
            LastNonInteractiveSignInDateTime = [datetime] '2026-03-05'
            LastSuccessfulSignInDateTime     = $null
        }
        Get-EgtLastSignIn -SignInActivity $activity | Should -Be ([datetime] '2026-03-05')
    }
}

Describe 'Get-EgtInactiveUser' {
    BeforeAll {
        $now = [datetime] '2026-06-01'
        Mock Get-MgUser {
            @(
                [pscustomobject] @{ DisplayName = 'Active'; UserPrincipalName = 'active@contoso.com'; UserType = 'Member'; CreatedDateTime = [datetime] '2024-01-01'
                    SignInActivity = [pscustomobject] @{ LastSignInDateTime = [datetime] '2026-05-20' } }
                [pscustomobject] @{ DisplayName = 'Stale'; UserPrincipalName = 'stale@contoso.com'; UserType = 'Member'; CreatedDateTime = [datetime] '2024-01-01'
                    SignInActivity = [pscustomobject] @{ LastSignInDateTime = [datetime] '2025-12-01' } }
                [pscustomobject] @{ DisplayName = 'Never'; UserPrincipalName = 'never@contoso.com'; UserType = 'Member'; CreatedDateTime = [datetime] '2025-01-01'
                    SignInActivity = $null }
                [pscustomobject] @{ DisplayName = 'New'; UserPrincipalName = 'new@contoso.com'; UserType = 'Member'; CreatedDateTime = [datetime] '2026-05-25'
                    SignInActivity = $null }
                [pscustomobject] @{ DisplayName = 'Guest'; UserPrincipalName = 'guest@fabrikam.com'; UserType = 'Guest'; CreatedDateTime = [datetime] '2024-01-01'
                    SignInActivity = [pscustomobject] @{ LastSignInDateTime = [datetime] '2025-01-01' } }
            )
        }
    }

    It 'returns stale and never-signed-in members only' {
        $result = Get-EgtInactiveUser -Days 90 -Now $now
        $result.DisplayName | Should -Be @('Stale', 'Never')
    }

    It 'includes guests when asked' {
        $result = Get-EgtInactiveUser -Days 90 -Now $now -IncludeGuests
        $result.DisplayName | Should -Contain 'Guest'
    }

    It 'calculates days inactive' {
        $stale = Get-EgtInactiveUser -Days 90 -Now $now | Where-Object DisplayName -EQ 'Stale'
        $stale.DaysInactive | Should -Be 182
    }
}

Describe 'Get-EgtLicenseSummary' {
    BeforeAll {
        Mock Get-MgSubscribedSku {
            @(
                [pscustomobject] @{ SkuPartNumber = 'SPE_E3'; ConsumedUnits = 90; PrepaidUnits = [pscustomobject] @{ Enabled = 100; Suspended = 0; Warning = 0 } }
                [pscustomobject] @{ SkuPartNumber = 'VISIOCLIENT'; ConsumedUnits = 2; PrepaidUnits = [pscustomobject] @{ Enabled = 2; Suspended = 0; Warning = 0 } }
            )
        }
    }

    It 'calculates free seats and usage' {
        $e3 = Get-EgtLicenseSummary | Where-Object Sku -EQ 'SPE_E3'
        $e3.Free | Should -Be 10
        $e3.UsedPercent | Should -Be 90
    }

    It 'filters by minimum free seats' {
        (Get-EgtLicenseSummary -MinimumFree 1).Sku | Should -Be 'SPE_E3'
    }
}

Describe 'Get-EgtGroupAudit' {
    BeforeAll {
        Mock Get-MgGroup {
            @(
                [pscustomobject] @{ Id = 'g1'; DisplayName = 'Healthy'; GroupTypes = @(); SecurityEnabled = $true; MailEnabled = $false; CreatedDateTime = [datetime] '2025-01-01' }
                [pscustomobject] @{ Id = 'g2'; DisplayName = 'Orphan'; GroupTypes = @('Unified'); SecurityEnabled = $false; MailEnabled = $true; CreatedDateTime = [datetime] '2025-01-01' }
            )
        }
        Mock Get-MgGroupOwner { if ($GroupId -eq 'g1') { [pscustomobject] @{ Id = 'u1' } } }
        Mock Get-MgGroupMemberCount { if ($GroupId -eq 'g1') { 5 } else { 0 } }
    }

    It 'flags groups without owners or members' {
        $orphan = Get-EgtGroupAudit | Where-Object DisplayName -EQ 'Orphan'
        $orphan.Issues | Should -Be 'NoOwners,NoMembers'
        $orphan.Kind | Should -Be 'Microsoft365'
    }

    It 'leaves healthy groups without issues' {
        $healthy = Get-EgtGroupAudit | Where-Object DisplayName -EQ 'Healthy'
        $healthy.Issues | Should -BeNullOrEmpty
        $healthy.Kind | Should -Be 'Security'
    }
}
