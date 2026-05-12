# disable update notifications.
# see https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_update_notifications?view=powershell-7.6
$env:POWERSHELL_UPDATECHECK = 'Off'
[Environment]::SetEnvironmentVariable(
    'POWERSHELL_UPDATECHECK',
    $env:POWERSHELL_UPDATECHECK,
    'Machine')

# install powershell lts.
# see https://github.com/PowerShell/PowerShell/releases
# renovate: datasource=github-releases depName=PowerShell/PowerShell extractVersion=^v(?<version>7\.6\..+)
$archiveVersion = '7.6.1'
$archiveUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$archiveVersion/PowerShell-$archiveVersion-win-x64.msi"
$archiveHash = '6b2118eb35379db159aa190ee2eb6721fe6b0e881b611429041ed13e8d8bea7b'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"

Write-Host "Downloading $archiveUrl..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash which does not match the expected $archiveHash"
}

Write-Host "Installing $archiveName..."
# see https://learn.microsoft.com/en-us/powershell/scripting/install/microsoft-update-faq?view=powershell-7.6#can-i-enable-these-update-options-from-the-command-line-or-in-a-script
msiexec /i $archivePath `
    /qn `
    /L*v "$archivePath.log" `
    USE_MU=0 `
    ENABLE_MU=0 `
    | Out-String -Stream
if ($LASTEXITCODE) {
    throw "$archiveName installation failed with exit code $LASTEXITCODE. See $archivePath.log."
}
Remove-Item $archivePath
