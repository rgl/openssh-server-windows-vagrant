# install dependencies.
choco install -y ruby --version 3.0.3.1

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# dump the ruby and the OpenSSL library versions.
ruby -v
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_VERSION'

# execute examples.
Get-ChildItem -Directory | ForEach-Object {
    Push-Location $_
    Write-Output "Running $($_.FullName)\run.ps1..."
    .\run.ps1
    Pop-Location
}
