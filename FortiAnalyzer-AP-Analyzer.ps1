#Requires -Version 5.1
<#
.SYNOPSIS
    FortiAnalyzer AP/Switch/Infrastructure Analyzer - CLI Tool
.DESCRIPTION
    Analyzes FortiAnalyzer logs to identify when and why APs, switches, or
    infrastructure components went offline or experienced issues.
    Supports Quick (daily monitoring) and Detailed (investigation) modes.
    Exports to Text, HTML, JSON, or CSV formats.
.PARAMETER LogPath
    Path to a FortiAnalyzer log file or directory containing log files.
.PARAMETER Mode
    Analysis mode: Quick (fast summary) or Detailed (comprehensive).
.PARAMETER OutputPath
    Path to save the analysis report. Auto-generated if omitted in Detailed mode.
.PARAMETER OutputFormat
    Export format: Text, HTML, JSON, or CSV. Default: auto-detect from OutputPath extension.
.PARAMETER DeviceName
    Filter events to a specific device hostname.
.PARAMETER StartTime
    Only include events at or after this time.
.PARAMETER EndTime
    Only include events at or before this time.
.PARAMETER LogLevel
    Minimum log severity level to include.
.PARAMETER MaxEvents
    Maximum events to display per category. Default: 10.
.PARAMETER RebootThreshold
    Maximum remotewtptime (seconds) to consider as an AP reboot. Default: 30.
.PARAMETER HighRFThreshold
    Frame failure count that triggers a HIGH RF warning. Default: 20.
.PARAMETER ShowAllEvents
    Show all events in Detailed mode, not just top N per category.
.PARAMETER Quiet
    Suppress console output (for automation/pipeline use). Results go to pipeline.
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-wireless.log"
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "C:\Logs\" -Mode Detailed -DeviceName "AP-01"
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -StartTime (Get-Date).AddDays(-7) -OutputFormat HTML -OutputPath report.html
.NOTES
    Version: 3.1.0
    Author:  FortiAnalyzer AP Analyzer Project
#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Leaf -ErrorAction SilentlyContinue })]
    [string]$LogPath,

    [Parameter()]
    [ValidateSet('Quick', 'Detailed')]
    [string]$Mode = 'Quick',

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [ValidateSet('Text', 'HTML', 'JSON', 'CSV')]
    [string]$OutputFormat,

    [Parameter()]
    [string]$DeviceName,

    [Parameter()]
    [datetime]$StartTime,

    [Parameter()]
    [datetime]$EndTime,

    [Parameter()]
    [ValidateSet('emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'information', 'debug')]
    [string]$LogLevel,

    [Parameter()]
    [ValidateRange(1, 10000)]
    [int]$MaxEvents = 10,

    [Parameter()]
    [ValidateRange(0.1, 3600)]
    [double]$RebootThreshold = 30.0,

    [Parameter()]
    [ValidateRange(0, 100000)]
    [int]$HighRFThreshold = 20,

    [switch]$ShowAllEvents,

    [switch]$Quiet
)

# Import the core module
$modulePath = Join-Path (Join-Path $PSScriptRoot 'src') 'FortiAnalyzer.Core.psm1'
if (-not (Test-Path $modulePath)) {
    throw "Core module not found at: $modulePath"
}
Import-Module $modulePath -Force

if (-not $Quiet) {
    $modeText = if ($Mode -eq 'Quick') { 'QUICK' } else { 'DETAILED' }
    Write-FortiStatus "[START] FortiAnalyzer AP Analyzer v3.1.0 - $modeText MODE" 'Header'
    Write-FortiStatus "[PATH] Log Path: $LogPath" 'Info'
}

# Resolve log files
$logFiles = @()
if (Test-Path $LogPath -PathType Container) {
    $logFiles = Get-ChildItem -Path $LogPath -Filter '*.log' | Select-Object -ExpandProperty FullName
} elseif (Test-Path $LogPath -PathType Leaf) {
    $logFiles = @($LogPath)
} else {
    throw "Log path not found: $LogPath"
}

if (-not $Quiet) {
    Write-FortiStatus "[FILES] Found $($logFiles.Count) log file(s)" 'Info'
}

# Read all log lines using List<T> for performance
$allLogLines = [System.Collections.Generic.List[string]]::new()
foreach ($file in $logFiles) {
    if (-not $Quiet) {
        Write-FortiStatus "[READ] Reading: $(Split-Path $file -Leaf)" 'Info'
    }
    $reader = [System.IO.File]::ReadLines($file, [System.Text.Encoding]::UTF8)
    foreach ($line in $reader) {
        $allLogLines.Add($line)
    }
}

if (-not $Quiet) {
    Write-FortiStatus "[LINES] Total log lines: $($allLogLines.Count)" 'Info'
}

# Run analysis
$analysisParams = @{
    LogLines        = $allLogLines.ToArray()
    RebootThreshold = $RebootThreshold
}
if ($DeviceName) { $analysisParams['DeviceFilter'] = $DeviceName }
if ($StartTime)  { $analysisParams['StartTime'] = $StartTime }
if ($EndTime)    { $analysisParams['EndTime'] = $EndTime }
if ($LogLevel)   { $analysisParams['LogLevel'] = $LogLevel }

$results = Get-FortiAnalysisResults @analysisParams

# Generate recommendations
$recommendations = New-FortiRecommendation -Results $results -HighRFThreshold $HighRFThreshold

# Display results
if ($Quiet) {
    $results | Add-Member -NotePropertyName 'Recommendations' -NotePropertyValue $recommendations -PassThru
    return
}

if ($Mode -eq 'Quick') {
    Write-FortiDashboard -Results $results

    Write-Host ''
    Write-Host '  RECOMMENDATIONS' -ForegroundColor Yellow
    Write-Host ('-' * 70) -ForegroundColor DarkGray
    foreach ($rec in $recommendations) {
        $color = switch ($rec.Level) {
            'Critical' { 'Red' }
            'Warning'  { 'Yellow' }
            'OK'       { 'Green' }
            default    { 'Cyan' }
        }
        Write-Host "    [$($rec.Level)] " -NoNewline -ForegroundColor $color
        Write-Host $rec.Message -ForegroundColor White
    }
} else {
    # Detailed mode
    Write-Host ''
    Write-Host ('=' * 80) -ForegroundColor White
    Write-Host '  DETAILED ANALYSIS RESULTS' -ForegroundColor Green
    Write-Host ('=' * 80) -ForegroundColor White

    $showCount = if ($ShowAllEvents) { [int]::MaxValue } else { $MaxEvents }

    # System Events
    Write-Host ''
    Write-Host "  SYSTEM & HA EVENTS ($($results.SystemEvents.Count))" -ForegroundColor Yellow
    if ($results.SystemEvents.Count -gt 0) {
        foreach ($evt in ($results.SystemEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Critical') { 'Red' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      Device: $($evt.Device) | $($evt.Message)" -ForegroundColor DarkGray
        }
        if ($results.SystemEvents.Count -gt $showCount) {
            Write-Host "    ... and $($results.SystemEvents.Count - $showCount) more" -ForegroundColor DarkGray
        }
    } else {
        Write-Host '    [OK] No system events' -ForegroundColor Green
    }

    # Switch Events
    Write-Host ''
    Write-Host "  SWITCH EVENTS ($($results.SwitchEvents.Count))" -ForegroundColor Yellow
    if ($results.SwitchEvents.Count -gt 0) {
        foreach ($evt in ($results.SwitchEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Critical') { 'Red' } elseif ($evt.Severity -eq 'Warning') { 'Yellow' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      Device: $($evt.Device) | $($evt.Message)" -ForegroundColor DarkGray
        }
        if ($results.SwitchEvents.Count -gt $showCount) {
            Write-Host "    ... and $($results.SwitchEvents.Count - $showCount) more" -ForegroundColor DarkGray
        }
    } else {
        Write-Host '    [OK] No switch events' -ForegroundColor Green
    }

    # Wireless Events
    Write-Host ''
    Write-Host "  WIRELESS EVENTS ($($results.WirelessEvents.Count))" -ForegroundColor Yellow
    if ($results.WirelessEvents.Count -gt 0) {
        foreach ($evt in ($results.WirelessEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Critical') { 'Red' } elseif ($evt.Severity -eq 'Warning') { 'Yellow' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      Source: $($evt.Source) | $($evt.Message)" -ForegroundColor DarkGray
        }
        if ($results.WirelessEvents.Count -gt $showCount) {
            Write-Host "    ... and $($results.WirelessEvents.Count - $showCount) more" -ForegroundColor DarkGray
        }
    } else {
        Write-Host '    [OK] No wireless events' -ForegroundColor Green
    }

    # SD-WAN Events
    if ($results.SDWANEvents.Count -gt 0) {
        Write-Host ''
        Write-Host "  SD-WAN EVENTS ($($results.SDWANEvents.Count))" -ForegroundColor Yellow
        foreach ($evt in ($results.SDWANEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Critical') { 'Red' } elseif ($evt.Severity -eq 'Warning') { 'Yellow' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      $($evt.Message)" -ForegroundColor DarkGray
        }
    }

    # VPN Events
    if ($results.VPNEvents.Count -gt 0) {
        Write-Host ''
        Write-Host "  VPN EVENTS ($($results.VPNEvents.Count))" -ForegroundColor Yellow
        foreach ($evt in ($results.VPNEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Warning') { 'Yellow' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      $($evt.Message)" -ForegroundColor DarkGray
        }
    }

    # Router Events
    if ($results.RouterEvents.Count -gt 0) {
        Write-Host ''
        Write-Host "  ROUTER EVENTS ($($results.RouterEvents.Count))" -ForegroundColor Yellow
        foreach ($evt in ($results.RouterEvents | Sort-Object DateTime -Descending | Select-Object -First $showCount)) {
            Write-Host "    [$($evt.Severity)] " -NoNewline -ForegroundColor $(if ($evt.Severity -eq 'Warning') { 'Yellow' } else { 'White' })
            Write-Host "$($evt.DateTime) | $($evt.Desc)" -ForegroundColor White
            Write-Host "      $($evt.Message)" -ForegroundColor DarkGray
        }
    }

    # Frame Failures
    Write-Host ''
    Write-Host "  FRAME FAILURES ($($results.FrameFailures.Count))" -ForegroundColor Yellow
    if ($results.FrameFailures.Count -gt 0) {
        $grouped = $results.FrameFailures | Group-Object Source | Sort-Object Count -Descending
        foreach ($g in $grouped) {
            Write-Host "    AP: $($g.Name) - $($g.Count) failures" -ForegroundColor White
        }
        Write-Host ''
        Write-Host '    Recent failures:' -ForegroundColor DarkGray
        foreach ($f in ($results.FrameFailures | Sort-Object DateTime -Descending | Select-Object -First 5)) {
            Write-Host "      $($f.DateTime): Client $($f.ClientMAC)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host '    [OK] No excessive frame failures' -ForegroundColor Green
    }

    # Recommendations
    Write-Host ''
    Write-Host ('-' * 80) -ForegroundColor DarkGray
    Write-Host '  RECOMMENDATIONS' -ForegroundColor Yellow
    Write-Host ('-' * 80) -ForegroundColor DarkGray
    foreach ($rec in $recommendations) {
        $color = switch ($rec.Level) {
            'Critical' { 'Red' }
            'Warning'  { 'Yellow' }
            'OK'       { 'Green' }
            default    { 'Cyan' }
        }
        Write-Host "    [$($rec.Level)] " -NoNewline -ForegroundColor $color
        Write-Host $rec.Message -ForegroundColor White
    }

    # Auto-generate report
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $logDir = if (Test-Path $LogPath -PathType Container) { $LogPath } else { Split-Path $LogPath -Parent }
        if (-not $logDir) { $logDir = '.' }
        $OutputPath = Join-Path $logDir "AP_Analysis_Report_$timestamp.html"
    }

    if (-not $OutputFormat) { $OutputFormat = 'HTML' }
    Export-FortiReport -Results $results -Recommendations $recommendations -OutputPath $OutputPath -Format $OutputFormat
    Write-FortiStatus "[REPORT] Report saved to: $OutputPath" 'Success'
}

Write-Host ''
Write-FortiStatus '[SUCCESS] Analysis completed.' 'Success'
