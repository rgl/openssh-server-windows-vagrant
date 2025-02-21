# install dependencies.
# see https://community.chocolatey.org/packages/ruby
# renovate: datasource=nuget:chocolatey depName=ruby
choco install -y ruby --version '3.3.0.1'

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the MSYS2 and MINGW development toolchain.
# NB this is required to to build native ruby extensions (e.g. ed25519).
# see https://community.chocolatey.org/packages/msys2#ruby-integration
ridk install 3

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
