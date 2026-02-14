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

$rsyncHome = 'C:\Program Files\rsync'
$openSshHome = 'C:\Program Files\OpenSSH'

function Install-RsyncBinaries {
    if (Test-Path $rsyncHome) {
        Write-Host "Removing the existing $rsyncHome..."
        Remove-Item -Force -Recurse $rsyncHome
    }
    if (Test-Path c:\vagrant\tmp\rsync-vagrant-*.zip) {
        $rsyncArtifact = Resolve-Path c:\vagrant\tmp\rsync-vagrant-*.zip
        Write-Host "Installing rsync from $rsyncArtifact..."
        Expand-Archive $rsyncArtifact $rsyncHome
    } else {
        # see https://github.com/rgl/rsync-vagrant/releases
        # renovate: datasource=github-releases depName=rgl/rsync-vagrant
        $version = '3.4.1-20250411'
        $url = "https://github.com/rgl/rsync-vagrant/releases/download/v$version/rsync-vagrant-$version.zip"
        Write-Host "Installing rsync from $url..."
        Install-ZippedApplication `
            $rsyncHome `
            rsync `
            $url `
            8a4492df681a66074b59513f4446ef660fe451187b2c943096fcde46a5c17a21
    }
    $rsyncCmdPath = if (Test-Path "$rsyncHome\cmd\rsync.exe") {
        "$rsyncHome\cmd"
    } else {
        $rsyncHome
    }
    &"$rsyncCmdPath\rsync.exe" --version
    $systemPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';'
    if ($rsyncHome -ne $rsyncCmdPath -and $systemPath -contains $rsyncHome) {
        $systemPath = $systemPath -ne $rsyncHome
        Write-Host "Removing $rsyncHome to the system PATH..."
        [Environment]::SetEnvironmentVariable(
            'PATH',
            "$($systemPath -join ';')",
            'Machine')
    }
    if ($systemPath -notcontains $rsyncCmdPath) {
        Write-Host "Adding $rsyncCmdPath to the system PATH..."
        $systemPath = @(
            $systemPath
            $rsyncCmdPath
        )
        [Environment]::SetEnvironmentVariable(
            'PATH',
            "$($systemPath -join ';')",
            'Machine')
    }
}

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
        while (Test-Path $openSshHome) {
            Write-Host 'Terminating the existing Win32-OpenSSH sshd and sshd-session processes...'
            Get-Process -ErrorAction SilentlyContinue sshd,sshd-session | Stop-Process -Force
            Write-Host 'Removing the existing Win32-OpenSSH sshd files...'
            Start-Sleep -Seconds 5 # give the os/processes a jiffy to stop and release the files from the FS before we delete'em all.
            Remove-Item -Recurse $openSshHome -ErrorAction SilentlyContinue
        }
    }
    # see https://github.com/PowerShell/Win32-OpenSSH/releases
    # renovate: datasource=github-releases depName=PowerShell/Win32-OpenSSH
    $version = '10.0.0.0p2-Preview'
    $url = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/$version/OpenSSH-Win64.zip"
    Write-Host "Installing Win32-OpenSSH from $url..."
    Install-ZippedApplication `
        $openSshHome `
        OpenSSH `
        $url `
        23f50f3458c4c5d0b12217c6a5ddfde0137210a30fa870e98b29827f7b43aba5
    Push-Location $openSshHome
    Move-Item OpenSSH-Win64\* .
    Remove-Item OpenSSH-Win64
    .\ssh.exe -V
    Pop-Location
}

# define a function for easing the execution of bash scripts.
function Bash($script) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        Write-Output 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH"' $script | C:\tools\msys64\usr\bin\bash.exe
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

Set-Location c:/vagrant
$script = Resolve-Path $script
Set-Location (Split-Path $script -Parent)
Write-Host "Running $script..."
. $script
