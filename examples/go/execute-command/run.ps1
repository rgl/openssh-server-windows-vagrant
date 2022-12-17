# build.
go build -buildvcs=false
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# execute.
Write-Output 'Executing command with ssh key...'
.\execute-command.exe -keyFile c:/vagrant/tmp/id_rsa -command 'whoami /all'
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
Write-Output 'Executing command with password...'
.\execute-command.exe -password vagrant -command 'whoami /all'
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
