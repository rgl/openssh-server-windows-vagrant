# install dependencies.
# see https://community.chocolatey.org/packages/temurin25
choco install -y temurin25
# see https://community.chocolatey.org/packages/gradle
# renovate: datasource=nuget:chocolatey depName=gradle
choco install -y gradle --version '9.1.0'

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
