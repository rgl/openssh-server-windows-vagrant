# install dependencies.
# see https://community.chocolatey.org/packages/temurin11
choco install -y temurin11
# see https://community.chocolatey.org/packages/gradle
choco install -y gradle --version 7.5.1

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
