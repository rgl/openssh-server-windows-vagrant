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
'sshd','ssh-agent' | ForEach-Object {
    Set-Service $_ -StartupType Automatic
    sc.exe failure $_ reset= 0 actions= restart/1000
}
sc.exe config sshd depend= ssh-agent
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH | Out-Null
Write-Host 'Saving the server public keys in the Vagrant shared folder at tmp/...'
mkdir -Force c:/vagrant/tmp | Out-Null
Copy-Item -Force "$openSshConfigHome\*.pub" c:/vagrant/tmp

Write-Host 'Generating a new SSH key at tmp/id_rsa and granting it access to the vagrant account...'
Remove-Item -ErrorAction SilentlyContinue c:/vagrant/tmp/id_rsa,c:/vagrant/tmp/id_rsa.pub
&"$openSshHome/ssh-keygen.exe" -q -f c:/vagrant/tmp/id_rsa -t rsa -b 2048 -C test -N '""'
mkdir -Force C:\Users\vagrant\.ssh | Out-Null
[IO.File]::WriteAllLines(
    'C:\Users\vagrant\.ssh\authorized_keys',
    [IO.File]::ReadAllLines('c:/vagrant/tmp/id_rsa.pub'))
