@{
    RootModule        = 'EntraGraphToolkit.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '6f3c2a8e-1d4b-4f7a-9c2e-8b5d7a1e3f90'
    Author            = 'Igor Demin'
    Description       = 'Read-only reports for Microsoft Entra ID and Microsoft 365 built on the Microsoft Graph PowerShell SDK.'
    PowerShellVersion = '7.2'
    RequiredModules   = @(
        'Microsoft.Graph.Authentication'
        'Microsoft.Graph.Users'
        'Microsoft.Graph.Groups'
        'Microsoft.Graph.Identity.DirectoryManagement'
    )
    FunctionsToExport = @(
        'Connect-EgtGraph'
        'Get-EgtInactiveUser'
        'Get-EgtLicenseSummary'
        'Get-EgtGroupAudit'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('EntraID', 'MicrosoftGraph', 'M365', 'Reporting')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
