# build.
go build -buildvcs=false
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# execute.
Write-Output 'Uploading file with ssh key...'
.\upload-file-sftp.exe -keyFile c:/vagrant/tmp/id_rsa -sourceFile main.go -destinationFile c:/tmp/upload-file-sftp-with-key.txt
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
Write-Output 'Uploading file with password...'
.\upload-file-sftp.exe -password vagrant -sourceFile main.go -destinationFile c:/tmp/upload-file-sftp-with-password.txt
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
