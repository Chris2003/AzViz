# Dot-sourced from each test file's BeforeAll block.
$script:ProjectRoot = Split-Path $PSScriptRoot -Parent
$script:ModuleRoot = Join-Path $ProjectRoot 'AzViz'
$script:ModuleManifest = Join-Path $ModuleRoot 'AzViz.psd1'
$script:FixtureRoot = Join-Path $PSScriptRoot 'fixtures'

Import-Module $ModuleManifest -Force -ErrorAction Stop
