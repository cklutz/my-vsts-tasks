#
# RunOpenCover.ps1 - Core script called by RunOpenCoverTask.ps1,
# but can also be called directly from a PowerShell build task.
#

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)][string]$sourcesDirectory,
    [Parameter(Mandatory=$true)][string]$testAssembly,
    [switch]$disableCodeCoverage,
    [string]$runTitle,
    [string]$platform,
    [string]$configuration,
    [string]$testAdapterPath,
    [string]$testFiltercriteria="",
    [string]$testAdditionalCommandLine,
    [string]$openCoverAdditionalCommandLine,
    [string]$openCoverFilters="+[*]*",
    [string]$vsTestCommand,
    [switch]$publishRunAttachments,
    [switch]$taskMode,
    [string]$toolsBaseDirectory,
    [string]$runSettingsFile
)

Trace-VstsEnteringInvocation $MyInvocation
Set-StrictMode -Version 3.0

$ErrorActionPreference = 'Stop'

Write-Verbose "Running task: $taskMode"

if (!$taskMode) {
    Import-Module "$PSScriptRoot\ps_modules\VstsTaskSdk"
}

function SendCommand($commandName, $properties, $data) {
    $command = '##vso['
    $command += $commandName

    $first = $true
    if ($properties -and $properties.Count -gt 0) {
        foreach ($key in $properties.Keys.GetEnumerator()) {
            $val = $properties[$key]
            if ($first) {
                $command += ' '
                $first = $false
            }
            $command += $key
            $command += '='
            $command += $val
            $command += ';'
        }
    }

    $command += ']'
    if ($data) {
        $command += $data.Replace('\r','%0D').Replace('\n', '%0A');
    }

    Write-Host $command
}

function FindCommand ($directory, $commandName) {
    Write-Host "Checking for '$commandName' in '$directory' tree"
    $results = Get-ChildItem -Path $directory -Filter $commandName -Recurse -ErrorAction SilentlyContinue -Force
    if (!$results -or $results.Length -eq 0) {
        throw "Command '$commandName' not found in directory tree '$directory' (source directory)."
    }
    Write-Host "Using $($results[0].FullName)"
    return $results[0].FullName
}

try {
    if (!$testAdapterPath) {
        if (Test-Path "$sourcesDirectory\.packages") {
            $testAdapterPath = "$sourcesDirectory\.packages"
        } elseif (Test-Path "$sourcesDirectory\packages") {
            $testAdapterPath = "$sourcesDirectory\packages"
        }
    }

    if ($toolsBaseDirectory) {
        $openCoverConsoleExe = FindCommand $toolsBaseDirectory "OpenCover.Console.exe"
        $coberturaConverterExe = FindCommand $toolsBaseDirectory "OpenCoverToCoberturaConverter.exe"
        $reportGeneratorExe = FindCommand $toolsBaseDirectory "ReportGenerator.exe"
    } else {
        Write-Host "Using packaged tools."
        $openCoverConsoleExe = "$PSScriptRoot\tools\OpenCover\OpenCover.Console.exe"
        $coberturaConverterExe = "$PSScriptRoot\tools\OpenCoverToCoberturaConverter\OpenCoverToCoberturaConverter.exe"
        $reportGeneratorExe = "$PSScriptRoot\tools\ReportGenerator\ReportGenerator.exe"
    }

    if ($vsTestCommand) {
        $vsconsoleExe = $vsTestCommand
    } else {
        $vsconsoleExe = "$env:VS140COMNTOOLS\..\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe"
    }
    Write-Host "Using VSTest: $vsconsoleExe"

    # resolve test assembly files (copied from VSTest.ps1)
    $testAssemblyFiles = @()
    # check for solution pattern
    if ($testAssembly.Contains("*") -Or $testAssembly.Contains("?"))
    {
        Write-Verbose "Pattern found in solution parameter. Calling Find-Files."
        Write-Verbose "Calling Find-Files with pattern: $testAssembly"    
        $testAssemblyFiles = Find-VstsFiles -LegacyPattern $testAssembly -LiteralDirectory $sourcesDirectory
        Write-Verbose "Found files: $testAssemblyFiles"
    }
    else
    {
        Write-Verbose "No Pattern found in solution parameter."
        $testAssembly = $testAssembly.Replace(';;', "`0") # Barrowed from Legacy File Handler
        foreach ($assembly in $testAssembly.Split(";"))
        {
            $testAssemblyFiles += ,($assembly.Replace("`0",";"))
        }
    }

    if ($testAssemblyFiles.Count -eq 0) {
        Write-Warning "Specified filter '$testAssembly' matches no files."
        Exit 0
    }

    Trace-VstsPath $testAssemblyFiles

    # build test assembly files string for vstest
    $testFilesString = ""
    foreach ($file in $testAssemblyFiles) {
        $testFilesString = $testFilesString + " ""$file"""
    }

    # Create tempDir underneath sources so that any publish-artificats task
    # don't pick stuff up accidentally.
    $tempDir = $sourcesDirectory + "\CoverageResults"
    # if ($runTitle) {
    #     $tempDir += '\' + $runTitle
    # }
    # if (Test-Path $tempDir) {
    #     Remove-Item -Path $tempDir -Recurse -Force
    # }

    if (-Not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory | Out-Null
    }
    $runId = $runTitle
    if (!$runId) {
        $runId = [Guid]::NewGuid().ToString("N")
    }
    $trxDir = "$tempDir\$runId"
    if (Test-path $trxDir) {
        Remove-Item -Recurse -Path $trxDir | Out-Null
    }
    New-Item -Path $trxDir -ItemType Directory | Out-Null
    
    $vsconsoleArgs = $testFilesString
    if ($testAdapterPath) { $vsconsoleArgs += " /TestAdapterPath:""$testAdapterPath""" }
    if ($testFilterCriteria) { $vsconsoleArgs += " /TestCaseFilter:""$testFiltercriteria""" }
    if ($runSettingsFile) { $vsconsoleArgs += " /Settings:""$runSettingsFile""" }
    $vsconsoleArgs += " /logger:trx"
    if ($testAdditionalCommandLine) {
        $vsconsoleArgs += " "
        $vsconsoleArgs += $testAdditionalCommandLine
    }

    if (!$disableCodeCoverage) {
        # According to "https://github.com/OpenCover/opencover/wiki/Usage",
        # "Notes on Spaces in Arguments", to preserve quotes in -targetargs,
        # we should escape them by a backslash.
        $vsconsoleArgs = $vsconsoleArgs.Replace('"', '\"')

        $openCoverConsoleArgs = "-register:user"
        if ($openCoverFilters) {
            # Only append filters, if there actually is a value. This way,
            # the caller could use a fully custom filter situation (e.g.
            # with -coverbytest, etc.) using the $openCoverAdditionalCommandLine
            # option.
            $openCoverConsoleArgs += " -filter:""$openCoverFilters"""
        }
        $openCoverConsoleArgs += " -target:""$vsconsoleExe"""
        $openCoverConsoleArgs += " -targetargs:""$vsconsoleArgs"""
        $openCoverConsoleArgs += " -mergeoutput"
        $openCoverConsoleArgs += " -output:""$tempDir\OpenCover.xml"""
        $openCoverConsoleArgs += " -mergebyhash"
        $openCoverConsoleArgs += " -returntargetcode"
        if ($openCoverAdditionalCommandLine) {
            $openCoverConsoleArgs += " "
            $openCoverConsoleArgs += $openCoverAdditionalCommandLine
        }

        $openCoverReport = "$tempDir\OpenCover.xml"
        $coberturaReport = "$tempDir\Cobertura.xml"
        $reportDirectory = "$tempDir\CoverageReport"

        $coberturaConverterArgs = "-input:""$openCoverReport"""
        $coberturaConverterArgs += " -output:""$coberturaReport"""
        $coberturaConverterArgs += " -sources:""$sourcesDirectory"""

        $reportGeneratorArgs = "-reports:""$openCoverReport"""
        $reportGeneratorArgs += " -targetdir:""$reportDirectory"""
        
        Invoke-VstsTool -FileName $openCoverConsoleExe -Arguments $openCoverConsoleArgs -WorkingDirectory $trxDir -RequireExitCodeZero
        Invoke-VstsTool -FileName $coberturaConverterExe -Arguments $coberturaConverterArgs -RequireExitCodeZero
        Invoke-VstsTool -FileName $reportGeneratorExe -Arguments $reportGeneratorArgs -RequireExitCodeZero
    } else {
        Invoke-VstsTool -FileName $vsconsoleExe -Arguments $vsconsoleArgs -WorkingDirectory $tempDir -RequireExitCodeZero
    }

    # Publish test results.
    $resultFiles = Find-VstsFiles -LegacyPattern "**\*.trx" -LiteralDirectory $trxDir
    $testResultParameters = [ordered]@{
        type = 'VSTest';
        resultFiles = $resultFiles;
        runTitle = $runTitle;
        platform = $platform;
        config = $configuration;
        publishRunAttachments = $publishRunAttachments
    }

    SendCommand 'results.publish' $testResultParameters ''
            
    if (!$disableCodeCoverage) {
        # Publish code coverage data.
        $codeCoverageParameters = [ordered]@{
            codecoveragetool = 'Cobertura';
            summaryfile = $coberturaReport
            reportdirectory = $reportDirectory
            additionalcodecoveragefiles = $openCoverReport
        }

        SendCommand 'codecoverage.publish' $codeCoverageParameters ''
    }
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}