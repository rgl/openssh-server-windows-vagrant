# download and install.
# see https://github.com/jtesta/ssh-audit/releases
# renovate: datasource=github-releases depName=jtesta/ssh-audit
$version = '3.3.0'
$archiveUrl = "https://github.com/jtesta/ssh-audit/releases/download/v${version}/ssh-audit.exe"
$archivePath = "$env:ChocolateyInstall\bin\ssh-audit.exe"
if (!(Test-Path $archivePath)) {
    Write-Host "Downloading $archiveUrl..."
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
}

# install ansi2html.
# see https://pypi.org/project/ansi2html/
# see https://github.com/pycontribs/ansi2html/releases
# renovate: datasource=pypi depName=ansi2html
$ansi2htmlVersion = '1.9.2'
if (!(Get-Command -ErrorAction SilentlyContinue ansi2html)) {
    Write-Host "Installing ansi2html $ansi2htmlVersion..."
    python -m pip install "ansi2html==$ansi2htmlVersion"
    if ($LASTEXITCODE) {
        throw "failed to install with exit code $LASTEXITCODE"
    }
}

# execute ssh-audit and save the result in the host README.md.
Write-Host "Executing ssh-audit sshd.example.com..."
$html = (ssh-audit sshd.example.com | ansi2html --inline) `
    -join "`n" `
    -replace '>(\(fin\) .+?: .+?:).+?<','>$1REDACTED<'
$readme = (Get-Content -Raw /vagrant/README.md) `
    -replace '(?smi)# sshd audit.*',"# sshd audit`n`n<pre>$html</pre>"
Set-Content /vagrant/README.md $readme
