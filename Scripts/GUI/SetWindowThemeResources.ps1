<#
    .SYNOPSIS
    Applies light or dark theme colors to a WPF window's resource dictionary.

    .DESCRIPTION
    Iterates over a predefined set of theme color categories and
    populates the window's Resources with SolidColorBrush entries keyed by
    category and resource name (e.g. "AppAccentColor"). Additionally loads and
    merges shared XAML styles from the script's SharedStylesSchema path if
    available. Also resolves the icon font: Segoe Fluent Icons on Windows 11
    and Segoe MDL2 Assets on Windows 10.

    .PARAMETER window
    The WPF Window whose resource dictionary will be populated.

    .PARAMETER usesDarkMode
    When $true, dark theme colors are applied; when $false, light theme colors.

    .EXAMPLE
    SetWindowThemeResources -window $MainWindow -usesDarkMode $true

    .EXAMPLE
    SetWindowThemeResources -window $Dialog -usesDarkMode $false
#>
# Sets resource colors for a WPF window based on dark mode preference
function SetWindowThemeResources {
    param (
        $window,
        [bool]$usesDarkMode
    )

        $ThemeColor = @{
        App = @{
            AccentColor = @{ Light = '#FF0000'; Dark = '#FF0000' }
            BorderColor = @{ Light = '#222222'; Dark = '#222222' }
            BgColor     = @{ Light = '#0A0A0A'; Dark = '#0A0A0A' }
            FgColor     = @{ Light = '#FFFFFF'; Dark = '#FFFFFF' }
            IdColor     = @{ Light = '#888888'; Dark = '#888888' }
        }

        Card = @{
            BgColor = @{ Light = '#121212'; Dark = '#121212' }
        }

        Button = @{
            BorderColor       = @{ Light = '#FF0000'; Dark = '#FF0000' }
            BgColor           = @{ Light = '#FF0000'; Dark = '#FF0000' }
            DisabledColor     = @{ Light = '#333333'; Dark = '#333333' }
            HoverColor        = @{ Light = '#CC0000'; Dark = '#CC0000' }
            PressedColor      = @{ Light = '#990000'; Dark = '#990000' }
            TextDisabledColor = @{ Light = '#555555'; Dark = '#555555' }
        }

        SecondaryButton = @{
            BgColor           = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
            DisabledColor     = @{ Light = '#111111'; Dark = '#111111' }
            HoverColor        = @{ Light = '#2A2A2A'; Dark = '#2A2A2A' }
            PressedColor      = @{ Light = '#3A3A3A'; Dark = '#3A3A3A' }
            TextDisabledColor = @{ Light = '#555555'; Dark = '#555555' }
        }

        CheckBox = @{
            BgColor     = @{ Light = '#121212'; Dark = '#121212' }
            BorderColor = @{ Light = '#FF0000'; Dark = '#FF0000' }
            HoverColor  = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
        }

        ComboBox = @{
            BgColor           = @{ Light = '#121212'; Dark = '#121212' }
            HoverColor        = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
            ItemBgColor       = @{ Light = '#121212'; Dark = '#121212' }
            ItemHoverColor    = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
            ItemSelectedColor = @{ Light = '#FF0000'; Dark = '#FF0000' }
        }

        TextBox = @{
            BorderColor     = @{ Light = '#FF0000'; Dark = '#FF0000' }
            BgColor         = @{ Light = '#121212'; Dark = '#121212' }
            FocusColor      = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
            HoverColor      = @{ Light = '#1A1A1A'; Dark = '#1A1A1A' }
            SideBorderColor = @{ Light = '#121212'; Dark = '#121212' }
        }

        ScrollBar = @{
            ThumbColor      = @{ Light = '#333333'; Dark = '#333333' }
            ThumbHoverColor = @{ Light = '#555555'; Dark = '#555555' }
        }

        TitleBar = @{
            ButtonHoverColor   = @{ Light = '#222222'; Dark = '#222222' }
            ButtonPressedColor = @{ Light = '#333333'; Dark = '#333333' }
            CloseHoverColor    = @{ Light = '#FF0000'; Dark = '#FF0000' }
            ClosePressedColor  = @{ Light = '#CC0000'; Dark = '#CC0000' }
            UnfocusedFgColor   = @{ Light = '#888888'; Dark = '#888888' }
        }

        Search = @{
            HighlightActiveColor = @{ Light = '#CC0000'; Dark = '#CC0000' }
            HighlightColor       = @{ Light = '#4A0000'; Dark = '#4A0000' }
        }

        Table = @{
            HeaderColor = @{ Light = '#121212'; Dark = '#121212' }
        }

        Icon = @{
            ErrorColor       = @{ Light = '#e81123'; Dark = '#e81123' }
            InformationColor = @{ Light = '#0078d4'; Dark = '#0078d4' }
            QuestionColor    = @{ Light = '#0078d4'; Dark = '#0078d4' }
            SuccessColor     = @{ Light = '#107c10'; Dark = '#107c10' }
            WarningColor     = @{ Light = '#ffb900'; Dark = '#ffb900' }
        }
    }

    $Theme = if ($usesDarkMode) { 'Dark' } else { 'Light' }

    foreach ($Group in $ThemeColor.GetEnumerator()) {
        foreach ($Resource in $Group.Value.GetEnumerator()) {
            $ResourceName = $Group.Key + $Resource.Key
            $window.Resources[$ResourceName] = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.ColorConverter]::ConvertFromString($Resource.Value[$Theme])
            )
        }
    }

    # Segoe Fluent Icons ships only on Windows 11 (build >= 22000). 
    # On Windows 10, fall back to Segoe MDL2 Assets.
    $winBuild = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild
    $iconFontName = if ($winBuild -ge 22000) { 'Segoe Fluent Icons' } else { 'Segoe MDL2 Assets' }
    $window.Resources['AppIconFontFamily'] = [System.Windows.Media.FontFamily]::new($iconFontName)

    # Load and merge shared styles
    if ($script:SharedStylesSchema -and (Test-Path $script:SharedStylesSchema)) {
        $sharedXaml = Get-Content -Path $script:SharedStylesSchema -Raw
        $sharedReader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($sharedXaml))
        try {
            $sharedDict = [System.Windows.Markup.XamlReader]::Load($sharedReader)
            $window.Resources.MergedDictionaries.Add($sharedDict)
        }
        finally {
            $sharedReader.Close()
        }
    }
}


