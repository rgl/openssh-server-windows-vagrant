Write-Host 'Creating Desktop shortcuts...'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Remove-Item -Force 'C:\Users\Public\Desktop\*.lnk'
Remove-Item -Force "$env:USERPROFILE\Desktop\*.lnk"
Install-ChocolateyShortcut `
    -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
    -TargetPath 'C:\Windows\System32\services.msc'

Write-Host 'Installing the PowerShell/Win32-OpenSSH service...'
# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
# NB Binaries are in $openSshHome (C:\Program Files\OpenSSH).
# NB Configuration, keys, and logs are in $openSshConfigHome (C:\ProgramData\ssh).
Install-OpenSshBinaries
$openSshConfigHome = 'C:\ProgramData\ssh'
$originalSshdConfig = Get-Content -Raw "$openSshHome\sshd_config_default"
# Configure the Administrators group to also use the ~/.ssh/authorized_keys file.
# see https://github.com/PowerShell/Win32-OpenSSH/issues/1324
$sshdConfig = $originalSshdConfig `
    -replace '(?m)^(Match Group administrators.*)','#$1' `
    -replace '(?m)^(\s*AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys.*)','#$1'
Set-Content -Encoding Ascii "$openSshConfigHome\sshd_config" $sshdConfig
&"$openSshHome\install-sshd.ps1"
&"$openSshHome\ssh-keygen.exe" -A
if ($LASTEXITCODE) {
    throw "Failed to run ssh-keygen with exit code $LASTEXITCODE"
}
Set-Content `
    -Encoding Ascii `
    "$openSshConfigHome\sshd_config" `
    ( `
        (Get-Content "$openSshConfigHome\sshd_config") `
            -replace '#?\s*UseDNS .+','UseDNS no' `
    )
&"$openSshHome\FixHostFilePermissions.ps1" -Confirm:$false
Set-Service 'sshd' -StartupType Automatic
sc.exe failure 'sshd' reset= 0 actions= restart/1000
sc.exe failure 'ssh-agent' reset= 0 actions= restart/1000
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH | Out-Null
Write-Host 'Saving the server public keys in the Vagrant shared folder at tmp/...'
mkdir -Force c:/vagrant/tmp | Out-Null
Copy-Item -Force "$openSshConfigHome\*.pub" c:/vagrant/tmp

Write-Host 'Generating a new SSH key at tmp/id_rsa and granting it access to the vagrant account...'
Remove-Item -ErrorAction SilentlyContinue c:/vagrant/tmp/id_rsa,c:/vagrant/tmp/id_rsa.pub
&"$openSshHome/ssh-keygen.exe" -q -f c:\tmp\id_rsa -m pem -t rsa -b 2048 -C test -N '""'
Move-Item c:\tmp\id_rsa,c:\tmp\id_rsa.pub c:\vagrant\tmp
mkdir -Force C:\Users\vagrant\.ssh | Out-Null
[IO.File]::WriteAllLines(
    'C:\Users\vagrant\.ssh\authorized_keys',
    [IO.File]::ReadAllLines('c:/vagrant/tmp/id_rsa.pub'))
