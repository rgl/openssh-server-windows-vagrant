# disable update notifications.
# see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_update_notifications?view=powershell-7.4
$env:POWERSHELL_UPDATECHECK = 'Off'
[Environment]::SetEnvironmentVariable(
    'POWERSHELL_UPDATECHECK',
    $env:POWERSHELL_UPDATECHECK,
    'Machine')

# install powershell lts.
# see https://github.com/PowerShell/PowerShell/releases
# renovate: datasource=github-releases depName=PowerShell/PowerShell extractVersion=^v(?<version>7\.4\..+)
$archiveVersion = '7.4.7'
$archiveUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$archiveVersion/PowerShell-$archiveVersion-win-x64.msi"
$archiveHash = '217b5575398d5e4a0ac67aff7b468c696a66c3e209685cf338032fc0a5f032ec'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"

Write-Host "Downloading $archiveName..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash which does not match the expected $archiveHash"
}

Write-Host "Installing $archiveName..."
msiexec /i $archivePath `
    /qn `
    /L*v "$archivePath.log" `
    | Out-String -Stream
if ($LASTEXITCODE) {
    throw "$archiveName installation failed with exit code $LASTEXITCODE. See $archivePath.log."
}
Remove-Item $archivePath
