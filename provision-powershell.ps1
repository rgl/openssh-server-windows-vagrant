# install powershell lts.
# see https://github.com/PowerShell/PowerShell/releases
$archiveUrl = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.8/PowerShell-7.2.8-win-x64.msi'
$archiveHash = '9a27962c3652c85193c6f3678741a712e880aa9f85f403774cd632c5cb8680ff'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"

Write-Host "Downloading $archiveName..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
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
