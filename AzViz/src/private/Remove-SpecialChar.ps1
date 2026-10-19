function Remove-SpecialChar {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Pure string transformation; no system state is changed.')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$String,
        [string]$SpecialChars = "()[]{}&."
    )

    $String -replace $($SpecialChars.ToCharArray().ForEach( { [regex]::Escape($_) }) -join "|"), ""
}
