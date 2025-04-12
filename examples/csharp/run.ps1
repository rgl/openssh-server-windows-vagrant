# see https://community.chocolatey.org/packages/dotnet-8.0-sdk
# see https://dotnet.microsoft.com/en-us/download/dotnet/8.0
# renovate: datasource=nuget:chocolatey depName=dotnet-8.0-sdk
choco install -y dotnet-8.0-sdk --version '8.0.407'

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# show information about dotnet.
dotnet --info

# execute examples.
Get-ChildItem -Directory | ForEach-Object {
    Push-Location $_
    Write-Output "Running $($_.FullName)\run.ps1..."
    .\run.ps1
    Pop-Location
}
