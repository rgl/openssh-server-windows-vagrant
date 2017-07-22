Write-Output 'Installing the native ssh client...'
Install-OpenSshBinaries

Write-Output 'Running a command on the sshd host with the native ssh client (you should see the "whoami /all" command output)...'
&"$openSshHome/ssh" vagrant@sshd.example.com 'whoami /all'

Write-Output 'Sending a file to the sshd host with the native scp client...'
&"$openSshHome/scp" native.ps1 vagrant@sshd.example.com:/tmp/example-powershell-native-scp.ps1

Write-Output 'Sending a file to the sshd host with the native sftp client...'
Write-Output 'put native.ps1 /tmp/example-powershell-native-sftp.ps1' | &"$openSshHome/sftp" -b - vagrant@sshd.example.com
