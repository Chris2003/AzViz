# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Breaking

- **PowerShell 7.4 or later is required.** Windows PowerShell 5.1 is no longer
  supported (`PowerShellVersion = '7.4'`, `CompatiblePSEditions = 'Core'`).
- **Progress output moved to the information stream.** `Export-AzViz` no longer
  uses `Write-Host`. Progress messages are written with `Write-Information`
  (tag `AzViz`) and are hidden by default. Use `-InformationAction Continue`
  to show them or `-InformationVariable` to capture them.
- **Errors are terminating.** `Export-AzViz` used to catch every error and write
  it to the output stream. It now rethrows, so scripts can use `try`/`catch`
  and CI jobs fail as expected.
- **No interactive sign-in.** AzViz no longer calls `Connect-AzAccount` for you.
  If there is no Azure context, it throws an error asking you to sign in first.

### Added

- `Export-AzVizTenant` exports one diagram per resource group for every
  subscription you can access. `Get-TenantDiagrams` is kept as an alias.
- The `AzViz` alias for `Export-AzViz` is now actually defined. It was listed in
  the manifest but never created.
- Pester 5 test suite that runs offline against synthetic fixtures, and a CI
  test matrix covering Windows, Ubuntu and macOS.

### Fixed

- Graphviz is run with the call operator on every platform. On Linux it was
  run through `Invoke-Expression` with an unquoted path.
- A missing Graphviz produces a clear "Graphviz is not installed" error with
  install hints, instead of a `CommandNotFound` error.
- The `File` and `Url` ARM template sources in `ConvertFrom-ARM` can now be
  reached. Temporary template files are always cleaned up, including when no
  resources are found or the export fails.
- The tenant export calls `Export-AzViz` (it called a non-existent `Get-AzViz`)
  and builds paths that work on Linux and macOS.
- `-Direction` is passed through to the diagram. It was ignored before.
- The source file `ConvertTo-DOTLangauge.ps1` is renamed to
  `ConvertTo-DOTLanguage.ps1`.
- PSScriptAnalyzer reports no Warning or Error findings.

## [1.2.1]

See the release notes in `AzViz/AzViz.psd1`.
