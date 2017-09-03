[CmdletBinding()]
param()

Set-StrictMode -Version 3.0

Trace-VstsEnteringInvocation $MyInvocation
try {

    $sourcesDirectory = Get-VstsInput "sourcesDirectory" -Require
    $testAssembly = Get-VstsInput "testAssembly" -Require
    $testAdditionalCommandLine = Get-VstsInput "testAdditionalCommandLine"
    $openCoverAdditionalCommandLine = Get-VstsInput "openCoverAdditionalCommandLine"
    $testAdapterPath = Get-VstsInput "testAdapterPath"
    $openCoverFilters = Get-VstsInput "openCoverFilters" -Default "+[*]*"
    $testFilterCriteria = Get-VstsInput "testFiltercriteria"
    $disableCodeCoverage = Get-VstsInput "disableCodeCoverage" -Default $false -AsBool
    $vsTestCommand = Get-VstsInput "vsTestCommand"
    $runTitle = Get-VstsInput "testRunTitle"
    $configuration = Get-VstsInput "configuration"
    $platform = Get-VstsInput "platform"
    $publishRunAttachments = Get-VstsINput "publishRunAttachments" -Default $false -AsBool

    . $PSScriptRoot\RunOpenCover.ps1 `
        -sourceDirectory $sourcesDirectory `
        -testAssembly $testAssembly `
        -testAdditionalCommandLine $testAdditionalCommandLine `
        -openCoverAdditionalCommandLine $openCoverAdditionalCommandLine `
        -testAdapterPath $testAdapterPath `
        -openCoverFilters $openCoverFilters `
        -testFilterCriteria $testFilterCriteria `
        -disableCodeCoverage $disableCodeCoverage `
        -vsTestCommand $vsTestCommand `
        -runTitle $runTitle `
        -configuration $configuration `
        -platform $platform `
        -plublishRunAttachments $publishRunAttachments

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}