Write-Host 'Creating Desktop shortcuts...'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Remove-Item -Force 'C:\Users\Public\Desktop\*.lnk'
Remove-Item -Force "$env:USERPROFILE\Desktop\*.lnk"
Install-ChocolateyShortcut `
    -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
    -TargetPath 'C:\Windows\System32\services.msc'

Write-Host 'Installing the PowerShell/Win32-OpenSSH service...'
# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
Install-OpenSshBinaries
Push-Location $openSshHome
. .\install-sshd.ps1
.\ssh-keygen.exe -A
if ($LASTEXITCODE) {
    throw "Failed to run ssh-keygen with exit code $LASTEXITCODE"
}
Set-Content `
    -Encoding Ascii `
    sshd_config `
    ( `
        (Get-Content sshd_config) `
            -replace '#?\s*UseDNS .+','UseDNS no' `
    )
.\FixHostFilePermissions.ps1 -Confirm:$false
Set-Service sshd -StartupType Automatic
sc.exe failure sshd reset= 0 actions= restart/1000
sc.exe failure ssh-agent reset= 0 actions= restart/1000
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH | Out-Null
Write-Host 'Saving the server public keys in the Vagrant shared folder at tmp/...'
mkdir -Force c:/vagrant/tmp | Out-Null
Copy-Item -Force *.pub c:/vagrant/tmp
Pop-Location

Write-Host 'Generating a new SSH key at tmp/id_rsa and granting it access to the vagrant account...'
Remove-Item -ErrorAction SilentlyContinue c:/vagrant/tmp/id_rsa,c:/vagrant/tmp/id_rsa.pub
&"$openSshHome/ssh-keygen.exe" -q -f c:/vagrant/tmp/id_rsa -t rsa -b 2048 -C test -N '""'
mkdir -Force C:\Users\vagrant\.ssh | Out-Null
[IO.File]::WriteAllLines(
    'C:\Users\vagrant\.ssh\authorized_keys',
    [IO.File]::ReadAllLines('c:/vagrant/tmp/id_rsa.pub'))

Write-Host 'Granting the ssh server read access to the vagrant authorized_keys file...'
$authorizedKeyPath = 'C:\Users\vagrant\.ssh\authorized_keys'
$acl = Get-Acl $authorizedKeyPath
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule 'NT Service\sshd','Read','Allow'))
Set-Acl $authorizedKeyPath $acl
