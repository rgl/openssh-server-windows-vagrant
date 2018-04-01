# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# see https://github.com/dotnet/core/blob/master/release-notes/download-archives/2.1.103-sdk-download.md
$cliVersion = '2.1.103'
$cliHome = "c:\ProgramData\dotnet-sdk-$cliVersion"
$archiveName = "dotnet-sdk-$cliVersion-win-x64.zip"
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
Invoke-WebRequest "https://download.microsoft.com/download/E/2/6/E266C257-F7AF-4E79-8EA2-DF26031C84E2/$archiveName" -UseBasicParsing -OutFile $archivePath
Expand-Archive $archivePath -DestinationPath $cliHome
Remove-Item $archivePath

# add dotnet to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$cliHome",
    'Machine')

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# show information about dotnet.
dotnet --info

# execute examples.
Get-ChildItem -Directory | ForEach-Object {
    Push-Location $_
    Write-Output "Running $($_.FullName)\run.ps1..."
    .\run.ps1
    Pop-Location
}
