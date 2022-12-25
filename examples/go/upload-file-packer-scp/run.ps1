# build.
go build -buildvcs=false
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# execute.
Write-Output 'Uploading file with ssh key...'
.\upload-file-packer-scp.exe -keyFile c:/vagrant/tmp/id_rsa -sourceFile main.go -destinationFile c:/tmp/upload-file-packer-scp-with-key.txt
# TODO uncomment when https://github.com/PowerShell/Win32-OpenSSH/issues/2018 lands in a release.
# if ($LASTEXITCODE) {
#     throw "failed with exit code $LASTEXITCODE"
# }
Write-Output 'Uploading file with password...'
.\upload-file-packer-scp.exe -password vagrant -sourceFile main.go -destinationFile c:/tmp/upload-file-packer-scp-with-password.txt
# TODO uncomment when https://github.com/PowerShell/Win32-OpenSSH/issues/2018 lands in a release.
# if ($LASTEXITCODE) {
#     throw "failed with exit code $LASTEXITCODE"
# }
