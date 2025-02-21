Write-Host 'Creating Desktop shortcuts...'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Remove-Item -Force 'C:\Users\Public\Desktop\*.lnk'
Remove-Item -Force "$env:USERPROFILE\Desktop\*.lnk"
Install-ChocolateyShortcut `
    -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
    -TargetPath 'C:\Windows\System32\services.msc'

Write-Host 'Installing the PowerShell/Win32-OpenSSH service...'
# install the binaries.
# see https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH
# NB Binaries are in $openSshHome (C:\Program Files\OpenSSH).
# NB Configuration, keys, and logs are in $openSshConfigHome (C:\ProgramData\ssh).
Install-OpenSshBinaries
# remove any existing configuration.
$openSshConfigHome = 'C:\ProgramData\ssh'
if (Test-Path $openSshConfigHome) {
    Remove-Item -Recurse -Force $openSshConfigHome
}
# modify the default configuration.
# NB sshd, at startup, if it does not already exists (as its the case of this
#    initial installation), will copy this file to
#    $openSshConfigHome\sshd_config.
# see https://github.com/PowerShell/openssh-portable/blob/v9.8.1.0/contrib/win32/win32compat/wmain_sshd.c#L152-L156
$sshdConfig = Get-Content -Raw "$openSshHome\sshd_config_default"
# Configure the Administrators group to also use the ~/.ssh/authorized_keys file.
# see https://github.com/PowerShell/Win32-OpenSSH/issues/1324
$sshdConfig = $sshdConfig `
    -replace '(?m)^(Match Group administrators.*)','#$1' `
    -replace '(?m)^(\s*AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys.*)','#$1'
# Disable UseDNS.
$sshdConfig = $sshdConfig `
    -replace '(?m)^#?\s*UseDNS .+','UseDNS no'
# Configure the powershell ssh subsystem (for powershell remoting over ssh).
# see https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core?view=powershell-7.4
$sshdConfig = $sshdConfig `
    -replace '(?m)^(Subsystem\s+sftp\s+.+)',"`$1`nSubsystem`tpowershell`tC:/Progra~1/PowerShell/7/pwsh.exe -nol -sshs"
Set-Content `
    -Encoding ascii `
    -NoNewline `
    -Path "$openSshHome\sshd_config_default" `
    -Value $sshdConfig
# install the service.
&"$openSshHome\install-sshd.ps1" -Confirm:$false
# start the service (it will create the configuration and host keys).
Start-Service sshd
# wait for all the files to be created.
while ($true) {
    $pendingFiles = @(
        ,'ssh_host_ecdsa_key.pub'
        ,'ssh_host_ecdsa_key'
        ,'ssh_host_ed25519_key.pub'
        ,'ssh_host_ed25519_key'
        ,'ssh_host_rsa_key.pub'
        ,'ssh_host_rsa_key'
        ,'sshd_config'
        ,'sshd.pid'
    ) | Where-Object {
        $filePath = "$openSshConfigHome\$_"
        !((Test-Path $filePath) -and (Get-Item $filePath).Length)
    }
    if (!$pendingFiles) {
        break
    }
    Start-Sleep -Seconds 5
}
Start-Sleep -Seconds 15
Stop-Service sshd

Write-Host 'Setting the host file permissions...'
&"$openSshHome\FixHostFilePermissions.ps1" -Confirm:$false

Write-Host 'Configuring sshd and ssh-agent services...'
# make sure the service startup type is delayed-auto.
# WARN do not be tempted to change the service startup type from
#      delayed-auto to auto, as the later proved to be unreliable.
$result = sc.exe config sshd start= delayed-auto
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config sshd failed with $result"
}
$result = sc.exe failure sshd reset= 0 actions= restart/60000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure sshd failed with $result"
}
$result = sc.exe failure ssh-agent reset= 0 actions= restart/60000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure ssh-agent failed with $result"
}

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

Write-Host 'Starting the sshd service...'
Start-Service sshd

Write-Host 'Allow firewall access to the sshd service port...'
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH | Out-Null
