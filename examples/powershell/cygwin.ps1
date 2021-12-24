# define a function for easying the execution of bash scripts.
$bashPath = "C:\tools\msys64\usr\bin\bash.exe"
function Bash($script) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        Write-Output 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH"' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

Write-Output 'Installing the cygwin ssh client...'
Bash 'pacman --noconfirm -Sy openssh'

Write-Output 'Importing the sshd host keys...'
Bash @'
mkdir -p ~/.ssh
find \
    /c/vagrant/tmp \
    -name 'ssh_host_*_key.pub' \
    -exec sh -c "(echo -n 'sshd.example.com '; cat {})" \; \
    >~/.ssh/known_hosts
'@

Write-Output 'Importing the ssh key...'
Bash @'
mkdir -p ~/.ssh
cp /c/vagrant/tmp/id_rsa* ~/.ssh
'@

Write-Output 'Running a command on the sshd host with the cygwin ssh client (you should see the "whoami /all" command output)...'
Bash 'ssh sshd.example.com "whoami /all"'

Write-Output 'Sending a file to the sshd host with the cygwin scp client...'
Bash 'scp cygwin.ps1 sshd.example.com:/tmp/example-powershell-cygwin-scp.ps1'

Write-Output 'Sending a file to the sshd host with the cygwin sftp client...'
Bash 'echo put cygwin.ps1 /tmp/example-powershell-cygwin-sftp.ps1 | sftp -b - sshd.example.com'
