function Get-EgtLicenseSummary {
    <#
    .SYNOPSIS
        Shows purchased, assigned and free seats for each subscribed SKU.

    .PARAMETER MinimumFree
        Only return SKUs with at least this many free seats. Useful for finding spend to cut.

    .EXAMPLE
        Get-EgtLicenseSummary | Sort-Object Free -Descending | Format-Table
    #>
    [CmdletBinding()]
    param(
        [int] $MinimumFree = 0
    )

    foreach ($sku in Get-MgSubscribedSku -All) {
        $purchased = [int] $sku.PrepaidUnits.Enabled
        $assigned  = [int] $sku.ConsumedUnits
        $free      = $purchased - $assigned

        if ($free -lt $MinimumFree) {
            continue
        }

        [pscustomobject] @{
            Sku         = $sku.SkuPartNumber
            Purchased   = $purchased
            Assigned    = $assigned
            Free        = $free
            Suspended   = [int] $sku.PrepaidUnits.Suspended
            Warning     = [int] $sku.PrepaidUnits.Warning
            UsedPercent = if ($purchased -gt 0) { [math]::Round(100 * $assigned / $purchased, 1) } else { $null }
        }
    }
}
