param(
    [Parameter(Mandatory=$true)]
    [String]$script
)

Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host "ERROR: $_"
    ($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1' | Write-Host
    ($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1' | Write-Host
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
function Install-ZippedApplication($destinationPath, $name, $url, $expectedHash='', $expectedHashAlgorithm='SHA256') {
    $localZipPath = "$env:TEMP\$name.zip"
    (New-Object Net.WebClient).DownloadFile($url, $localZipPath)
    if ($expectedHash) {
        $actualHash = (Get-FileHash $localZipPath -Algorithm $expectedHashAlgorithm).Hash
        if ($actualHash -ne $expectedHash) {
            throw "$name downloaded from $url to $localZipPath has $actualHash hash that does not match the expected $expectedHash"
        }
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
        Write-Host 'Terminating the existing Win32-OpenSSH sshd processes...'
        Get-Process -ErrorAction SilentlyContinue sshd | Stop-Process -Force
        Start-Sleep -Seconds 5 # give the os/processes a jiffy to stop and release the files from the FS before we delete'em all.
        Remove-Item -Recurse $openSshHome
    }
    Write-Host 'Installing Win32-OpenSSH...'
    # see https://github.com/PowerShell/Win32-OpenSSH/releases
    # renovate: datasource=github-releases depName=PowerShell/Win32-OpenSSH
    $openSshVersion = '9.1.0.0p1-Beta'
    Install-ZippedApplication `
        $openSshHome `
        OpenSSH `
        "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v$openSshVersion/OpenSSH-Win64.zip"
    Push-Location $openSshHome
    Move-Item OpenSSH-Win64\* .
    Remove-Item OpenSSH-Win64
    .\ssh.exe -V
    Pop-Location
}

Set-Location c:/vagrant
$script = Resolve-Path $script
Set-Location (Split-Path $script -Parent)
Write-Host "Running $script..."
. $script
