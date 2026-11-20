# entra-graph-toolkit

Small, read-only reports for Microsoft Entra ID and Microsoft 365, built on the
[Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph/overview).

The kind of checks an IT team runs every month: who hasn't signed in for a while,
which licences are paid for but unused, and which groups have no owner.

## Reports

| Command | What it returns |
| --- | --- |
| `Get-EgtInactiveUser` | Enabled accounts with no sign-in for N days (default 90), including accounts that never signed in |
| `Get-EgtLicenseSummary` | Purchased, assigned and free seats per SKU |
| `Get-EgtGroupAudit` | Groups with no owners or no members |

Everything is read-only: the module never changes users, groups or licences.

## Quick start

```powershell
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser

Import-Module ./EntraGraphToolkit
Connect-EgtGraph

Get-EgtInactiveUser -Days 60 | Format-Table
Get-EgtLicenseSummary -MinimumFree 5
Get-EgtGroupAudit -Filter "securityEnabled eq true" | Where-Object Issues
```

`examples/monthly-report.ps1` writes all three reports to CSV.

## Permissions

| Scope | Used for |
| --- | --- |
| `User.Read.All` | Reading users |
| `AuditLog.Read.All` | Reading `signInActivity` (needs Entra ID P1 or P2) |
| `Group.Read.All`, `GroupMember.Read.All` | Reading groups, owners and member counts |
| `Organization.Read.All` | Reading subscribed SKUs |

For scheduled runs, create an app registration with the same application permissions and connect with a certificate:

```powershell
Connect-EgtGraph -TenantId $tenantId -ClientId $appId -CertificateThumbprint $thumbprint
```

## Tests

Pester tests mock the Graph cmdlets, so they run without a tenant:

```powershell
Invoke-Pester ./tests
```

CI runs PSScriptAnalyzer and Pester on every push.

## License

MIT
