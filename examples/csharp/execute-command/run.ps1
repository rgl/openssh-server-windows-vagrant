# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics run --configuration Release
