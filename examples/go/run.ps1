# install dependencies.
# see https://community.chocolatey.org/packages/golang
# renovate: datasource=nuget:chocolatey depName=golang
choco install -y golang --version '1.24.2'

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# execute examples.
Get-ChildItem -Directory | ForEach-Object {
    Push-Location $_
    Write-Output "Running $($_.FullName)\run.ps1..."
    .\run.ps1
    Pop-Location
}
