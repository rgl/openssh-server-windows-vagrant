param(
    [Parameter(Mandatory=$true)]
    [String]$script
)

Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}

# enable TLS 1.1 and 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol `
    -bor [Net.SecurityProtocolType]::Tls11 `
    -bor [Net.SecurityProtocolType]::Tls12

# wrap the choco command (to make sure this script aborts when it fails).
function Start-Choco([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    $command, $commandArguments = $Arguments
    if ($command -eq 'install') {
        $Arguments = @($command, '--no-progress') + $commandArguments
    }
    for ($n = 0; $n -lt 10; ++$n) {
        if ($n) {
            # NB sometimes choco fails with "The package was not found with the source(s) listed."
            #    but normally its just really a transient "network" error.
            Write-Host "Retrying choco install..."
            Start-Sleep -Seconds 3
        }
        &C:\ProgramData\chocolatey\bin\choco.exe @Arguments
        if ($SuccessExitCodes -Contains $LASTEXITCODE) {
            return
        }
    }
    throw "$(@('choco')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
}
function choco {
    Start-Choco $Args
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Install-ZippedApplication($destinationPath, $name, $url, $expectedHash, $expectedHashAlgorithm='SHA256') {
    $localZipPath = "$env:TEMP\$name.zip"
    (New-Object Net.WebClient).DownloadFile($url, $localZipPath)
    $actualHash = (Get-FileHash $localZipPath -Algorithm $expectedHashAlgorithm).Hash
    if ($actualHash -ne $expectedHash) {
        throw "$name downloaded from $url to $localZipPath has $actualHash hash that does not match the expected $expectedHash"
    }
    [IO.Compression.ZipFile]::ExtractToDirectory($localZipPath, $destinationPath)
    Remove-Item $localZipPath
}

$openSshHome = 'C:\Program Files\OpenSSH'

function Install-OpenSshBinaries {
    if (Test-Path 'C:\Program Files\OpenSSH\uninstall.exe') {
        Write-Host 'Uninstalling the existing mls OpenSSH service...'
        Stop-Service OpenSSHd
        $p = Start-Process `
            -PassThru `
            -Wait `
            -FilePath 'C:\Program Files\OpenSSH\uninstall.exe' `
            -ArgumentList '/S'
        if ($p.ExitCode) {
            throw "Failed to uninstall mls OpenSSH server with exit code $($p.ExitCode)"
        }
        Remove-Item -Force -Recurse 'C:\Program Files\OpenSSH'
    }
    if (Test-Path "$openSshHome\uninstall-sshd.ps1") {
        if (Get-Service -ErrorAction SilentlyContinue sshd) {
            Write-Host 'Stopping the existing Win32-OpenSSH service...'
            Stop-Service -Force sshd
        }
        Write-Host 'Uninstalling the existing Win32-OpenSSH service...'
        &"$openSshHome\uninstall-sshd.ps1"
        Remove-Item -Recurse $openSshHome
    }
    Install-ZippedApplication `
        $openSshHome `
        OpenSSH `
        https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.7.1.0p1-Beta/OpenSSH-Win64.zip `
        b0e2d2afd43c76d609611839d6163eeceda2e5af791e7d90c6b1a811fd502342
    Push-Location $openSshHome
    Move-Item OpenSSH-Win64\* .
    Remove-Item OpenSSH-Win64
    Pop-Location
}

cd c:/vagrant
$script = Resolve-Path $script
cd (Split-Path $script -Parent)
Write-Host "Running $script..."
. $script
