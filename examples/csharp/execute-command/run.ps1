# restore the packages.
dotnet restore
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# build and run.
dotnet --diagnostics build --configuration Release
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
dotnet --diagnostics run --configuration Release
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
