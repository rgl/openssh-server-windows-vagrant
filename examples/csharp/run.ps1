# see https://dotnet.microsoft.com/download/dotnet/5.0
# see https://github.com/dotnet/core/blob/main/release-notes/5.0/5.0.13/5.0.13.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/44069ee2-ce02-41d7-bcc5-2168a1653278/cfc5131c81ae00a5f77f05f9963ec98d/dotnet-sdk-5.0.404-win-x64.exe'
$archiveHash = 'a2bdf552bb09a1f8315e383ca7d65b876c505de3c94dba4c5f530eddd7f03370bddd0832ef7f3cb876bb31b90cbeb8dc770ca1ce0a3a0cdf6c7bed48b30a7065'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA512).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host "Installing $archiveName..."
&$archivePath /install /quiet /norestart | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath

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
