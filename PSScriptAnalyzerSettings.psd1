@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Report functions return [pscustomobject] rows; a fixed OutputType adds little here.
        'PSUseOutputTypeCorrectly'
    )
}
