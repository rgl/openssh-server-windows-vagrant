# install dependencies.
choco install -y jdk8 gradle

# enable the Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy.
# see https://raw.githubusercontent.com/rgl/jce-chocolatey-package/master/tools/chocolateyInstall.ps1
$packageName = 'jdk8'
$javaRegistryKeyName = if ($packageName -like 'jre*') {'Java Runtime Environment'} else {'Java Development Kit'}
$javaHome = (Get-ItemProperty -Path "HKLM:\SOFTWARE\JavaSoft\$javaRegistryKeyName\1.8" -Name JavaHome).JavaHome
$jreHome = if ($packageName -like 'jre*') {$javaHome} else {"$javaHome\jre"}
Copy-Item -Force "$jreHome\lib\security\policy\unlimited\*" "$jreHome\lib\security"

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
