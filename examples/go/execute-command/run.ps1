# build.
go get golang.org/x/crypto/ssh
go build

# execute.
Write-Output 'Executing command with ssh key...'
.\execute-command.exe -keyFile c:/vagrant/tmp/id_rsa -command 'whoami /all'
Write-Output 'Executing command with password...'
.\execute-command.exe -password vagrant -command 'whoami /all'
