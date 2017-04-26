# set keyboard layout.
# NB you can get the name from the list:
#      [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | out-gridview
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the timezone.
# tzutil /l lists all available timezone ids
& $env:windir\system32\tzutil /s "GMT Standard Time"

# install chocolatey.
iex ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
choco install -y googlechrome
$chromeLocation = 'C:\Program Files (x86)\Google\Chrome\Application'
cp -Force GoogleChrome-external_extensions.json (Get-Item "$chromeLocation\*\default_apps\external_extensions.json").FullName
cp -Force GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# replace notepad with notepad++.
choco install -y notepadplusplus.install
$archiveUrl = 'https://github.com/rgl/ApplicationReplacer/releases/download/v0.0.1/ApplicationReplacer.zip'
$archiveHash = 'aeba158e5c7a6ecaaa95c8275b5bb4d6e032e016c6419adebb94f4e939b9a918'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Expand-Archive $archivePath -DestinationPath 'C:\Program Files\ApplicationReplacer'
Remove-Item $archivePath
New-Item -Force -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe' `
    | Set-ItemProperty `
        -Name Debugger `
        -Value '"C:\Program Files\ApplicationReplacer\ApplicationReplacer.exe" -- "C:\Program Files\Notepad++\notepad++.exe"'

Write-Host 'Creating Desktop shortcuts...'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Remove-Item -Force 'C:\Users\Public\Desktop\*.lnk'
Remove-Item -Force "$env:USERPROFILE\Desktop\*.lnk"
Install-ChocolateyShortcut `
    -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
    -TargetPath 'C:\Windows\System32\services.msc'

if (Test-Path 'C:\Program Files\OpenSSH') {
    Write-Host 'Uninstalling the existing mls OpenSSH service...'
    Stop-Service OpenSSHd
    $p = Start-Process `
        -PassThru `
        -Wait `
        -FilePath 'C:\Program Files\OpenSSH\uninstall.exe' `
        -ArgumentList '/S'
    if ($p.ExitCode) {
        throw "Failed to uninstall mls OpenSSH server with exit code $($p.ExitCode)"
    }
}

Write-Host 'Installing the PowerShell/Win32-OpenSSH service...'
# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
Install-OpenSshBinaries
Push-Location C:\OpenSSH
. .\install-sshd.ps1
.\ssh-keygen.exe -A
if ($LASTEXITCODE) {
    throw "Failed to run ssh-keygen with exit code $LASTEXITCODE"
}
Set-Service sshd -StartupType Automatic
cmd /c 'sc failure sshd reset= 0 actions= restart/1000/restart/1000/restart/1000'
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH | Out-Null
Write-Host 'Saving the server public keys in the Vagrant shared folder at tmp/...'
mkdir -Force c:/vagrant/tmp | Out-Null
Copy-Item -Force *.pub c:/vagrant/tmp
Pop-Location

Write-Host 'Generating a new SSH key at tmp/id_rsa and granting it access to the vagrant account...'
cmd /c 'c:/OpenSSH/ssh-keygen -q -f c:/vagrant/tmp/id_rsa -t rsa -b 2048 -C test -N ""'
mkdir -Force C:\Users\vagrant\.ssh | Out-Null
[IO.File]::WriteAllLines(
    'C:\Users\vagrant\.ssh\authorized_keys',
    [IO.File]::ReadAllLines('c:/vagrant/tmp/id_rsa.pub'))

Write-Host 'Granting the ssh server read access to the vagrant authorized_keys file...'
$authorizedKeyPath = 'C:\Users\vagrant\.ssh\authorized_keys'
$acl = Get-Acl $authorizedKeyPath
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule 'NT Service\sshd','Read','Allow'))
Set-Acl $authorizedKeyPath $acl
