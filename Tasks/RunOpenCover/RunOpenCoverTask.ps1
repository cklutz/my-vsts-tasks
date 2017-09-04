[CmdletBinding()]
param()

Set-StrictMode -Version 3.0

Trace-VstsEnteringInvocation $MyInvocation
try {

    $sourcesDirectory = Get-VstsInput -Name sourcesDirectory -Require
    $testAssembly = Get-VstsInput -Name testAssembly -Require
    $testAdditionalCommandLine = Get-VstsInput -Name testAdditionalCommandLine
    $openCoverAdditionalCommandLine = Get-VstsInput -Name openCoverAdditionalCommandLine
    $testAdapterPath = Get-VstsInput -Name testAdapterPath
    $openCoverFilters = Get-VstsInput -Name openCoverFilters -Default "+[*]*"
    $testFilterCriteria = Get-VstsInput -Name testFiltercriteria
    $disableCodeCoverage = Get-VstsInput -Name disableCodeCoverage -Default $false -AsBool
    $vsTestCommand = Get-VstsInput -Name vsTestCommand
    $runTitle = Get-VstsInput -Name testRunTitle
    $configuration = Get-VstsInput -Name configuration
    $platform = Get-VstsInput -Name platform
    $publishRunAttachments = Get-VstsInput -Name publishRunAttachments -Default $false -AsBool

    . $PSScriptRoot\RunOpenCover.ps1 `
        -sourcesDirectory $sourcesDirectory `
        -testAssembly $testAssembly `
        -testAdditionalCommandLine $testAdditionalCommandLine `
        -openCoverAdditionalCommandLine $openCoverAdditionalCommandLine `
        -testAdapterPath $testAdapterPath `
        -openCoverFilters $openCoverFilters `
        -testFilterCriteria $testFilterCriteria `
        -disableCodeCoverage:$disableCodeCoverage `
        -vsTestCommand $vsTestCommand `
        -runTitle $runTitle `
        -configuration $configuration `
        -platform $platform `
        -publishRunAttachments:$publishRunAttachments `
        -taskMode
} catch {

    $_ | format-list * -Force
    throw $_

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}