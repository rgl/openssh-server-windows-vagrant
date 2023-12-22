# download and install.
# see https://github.com/jtesta/ssh-audit/releases
# renovate: datasource=github-releases depName=jtesta/ssh-audit
$version = '3.1.0'
$archiveUrl = "https://github.com/jtesta/ssh-audit/releases/download/v${version}/ssh-audit.exe"
$archivePath = "$env:ChocolateyInstall\bin\ssh-audit.exe"
if (!(Test-Path $archivePath)) {
    Write-Host "Downloading $archiveUrl..."
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
}

# execute ssh-audit and save the result in the host README.md.
Write-Host "Executing ssh-audit sshd.example.com..."
ssh-audit sshd.example.com
