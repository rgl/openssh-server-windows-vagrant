# set keyboard layout.
# NB you can get the name from the list:
#      [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | out-gridview
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the UI language.
Set-WinUILanguageOverride en-US

# set the timezone.
# tzutil /l lists all available timezone ids
& $env:windir\system32\tzutil /s "GMT Standard Time"

# show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null

# set default Explorer location to This PC.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

# set the desktop wallpaper.
Add-Type @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class WindowsWallpaper
{
    private const int COLOR_DESKTOP = 0x01;

    [DllImport("user32", SetLastError=true)]
    private static extern bool SetSysColors(int cElements, int[] lpaElements, int[] lpaRgbValues);

    private const uint SPI_SETDESKWALLPAPER = 0x14;
    private const uint SPIF_UPDATEINIFILE = 0x01;
    private const uint SPIF_SENDWININICHANGE = 0x02;

    [DllImport("user32", SetLastError=true)]
    private static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);

    public static void Set(Color color, string path)
    {
        var elements = new int[] { COLOR_DESKTOP };
        var colors = new int[] { ColorTranslator.ToWin32(color) };
        SetSysColors(elements.Length, elements, colors);
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE);
    }
}
'@ -ReferencedAssemblies System.Drawing
function Set-Wallpaper {
    param (
        [Parameter(Mandatory = $True)]
        [ValidateSet(
            'Fill',
            'Fit',
            'Stretch',
            'Tile',
            'Center',
            'Span')]
        [string]$Style,
        [Parameter(Mandatory = $True)]
        [System.Drawing.Color]$Color,
        [Parameter(Mandatory = $True)]
        [string]$Path
    )
    $wallpaperStyle = switch ($Style) {
        'Fill' { '10' }
        'Fit' { '6' }
        'Stretch' { '2' }
        'Span' { '22' }
        default { '0' }
    }
    New-ItemProperty `
        -Path 'HKCU:\Control Panel\Desktop' `
        -Name WallpaperStyle `
        -PropertyType String `
        -Value $wallpaperStyle `
        -Force `
        | Out-Null
    New-ItemProperty `
        -Path 'HKCU:\Control Panel\Desktop' `
        -Name TileWallpaper `
        -PropertyType String `
        -Value "$(if ($Style -eq 'Tile') {'1'} else {'0'})" `
        -Force `
        | Out-Null
    New-ItemProperty `
        -Path 'HKCU:\Control Panel\Desktop' `
        -Name Wallpaper `
        -PropertyType String `
        -Value $Path `
        -Force `
        | Out-Null
    New-ItemProperty `
        -Path 'HKCU:\Control Panel\Colors' `
        -Name Background `
        -PropertyType String `
        -Value ($Color.R,$Color.G,$Color.B -join ' ') `
        -Force `
        | Out-Null
    # NB [WindowsWallpaper]::Set does not really work when running from WinRM.
    #    that is why we still set the Wallpaper and Background registry values.
    [WindowsWallpaper]::Set($Color, $Path)
}
$wallpaperSourcePath = 'openssh.png'
$wallpaperDestinationPath = 'C:\Windows\Web\Wallpaper\Windows\openssh.png'
Copy-Item $wallpaperSourcePath $wallpaperDestinationPath
$wallpaperImage = [System.Drawing.Image]::FromFile($wallpaperDestinationPath)
$wallpaperColor = $wallpaperImage.GetPixel(0, 0)
$wallpaperImage.Dispose()
Set-Wallpaper 'Center' $wallpaperColor $wallpaperDestinationPath

# install chocolatey.
iex ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
# NB this ignores the checksums of the chrome package. the upstream binaries
#    are not versioned so its somewhat impossible to have a package with
#    hardcoded checksums to a older binary work with a newer binary.
choco install -y googlechrome --ignore-checksums
$chromeLocation = 'C:\Program Files\Google\Chrome\Application'
cp -Force GoogleChrome-external_extensions.json (Resolve-Path "$chromeLocation\*\default_apps\external_extensions.json")
cp -Force GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# set the default browser.
choco install -y SetDefaultBrowser
SetDefaultBrowser HKLM 'Google Chrome'

# replace notepad with notepad3.
choco install -y notepad3
