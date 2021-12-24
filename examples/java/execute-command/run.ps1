# build.
gradle build --warning-mode all
if ($LASTEXITCODE) {
    Exit 1
}
Remove-Item -Force -Recurse -ErrorAction SilentlyContinue build\distributions\example-1.0.0
Expand-Archive build\distributions\example-1.0.0.zip build\distributions

# NB this script normally runs with $ErrorActionPreference = 'Stop', but we
#    need to change it to 'Continue' because the application writes to stderr
#    (which would abort this script).
$ErrorActionPreference = 'Continue'

# run the example.
Write-Output 'Executing command with ssh key...'
java -cp 'build/distributions/example-1.0.0/lib/*' Example --key-file c:/vagrant/tmp/id_rsa

Write-Output 'Executing command with password...'
java -cp 'build/distributions/example-1.0.0/lib/*' Example --password vagrant
