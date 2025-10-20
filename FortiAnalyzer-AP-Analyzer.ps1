#Requires -Version 5.1
<#
.SYNOPSIS
    FortiAnalyzer AP/Switch Offline Event Analyzer - Unified Tool
    
.DESCRIPTION
    Analyzes FortiAnalyzer wireless and system logs to identify when and why APs or switches went offline.
    Supports both quick analysis and detailed investigation modes.
    
.PARAMETER LogPath
    Path to the FortiAnalyzer log file or directory containing log files
    
.PARAMETER Mode
    Analysis mode: "Quick" for fast summary, "Detailed" for comprehensive analysis (default: Quick)
    
.PARAMETER OutputPath
    Optional path to save the analysis report (only used in Detailed mode)
    
.PARAMETER DeviceName
    Optional filter for specific device name (e.g., "BSC-WL-AP01")
    
.PARAMETER ShowInfraEvents
    Show infrastructure events in output (default: false for Quick mode, true for Detailed)
    
.PARAMETER MaxEvents
    Maximum number of events to display per category (default: 10)
    
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-event-wireless-2025_10_20.log"
    
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "C:\Logs\" -Mode Detailed -DeviceName "BSC-WL-AP01"
    
.EXAMPLE
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -Mode Quick -ShowInfraEvents
    
.NOTES
    Author: Network Analysis Tool
    Version: 2.0 - Unified Tool
    Created: 2025-10-20
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$LogPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Quick", "Detailed")]
    [string]$Mode = "Quick",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory=$false)]
    [string]$DeviceName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowInfraEvents,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxEvents = 10
)

# Initialize results object
$AnalysisResults = @{
    RebootEvents = @()
    InfrastructureEvents = @()
    FrameFailures = @()
    Recommendations = @()
    Summary = @{}
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Parse-FortiLogLine {
    param([string]$LogLine)
    
    $logData = @{}
    
    # Extract key-value pairs from FortiAnalyzer log format
    $patterns = @{
        'date' = 'date=([^\s]+)'
        'time' = 'time=([^\s]+)'
        'devname' = 'devname="([^"]+)"'
        'ap' = 'ap="([^"]+)"'
        'msg' = 'msg="([^"]+)"'
        'action' = 'action="([^"]+)"'
        'level' = 'level="([^"]+)"'
        'remotewtptime' = 'remotewtptime="([^"]+)"'
        'reason' = 'reason="([^"]+)"'
        'logid' = 'logid=([^\s]+)'
        'type' = 'type="([^"]+)"'
        'subtype' = 'subtype="([^"]+)"'
        'stamac' = 'stamac="([^"]+)"'
        'signal' = 'signal=([^\s]+)'
        'snr' = 'snr=([^\s]+)'
    }
    
    foreach ($key in $patterns.Keys) {
        if ($LogLine -match $patterns[$key]) {
            $logData[$key] = $matches[1]
        }
    }
    
    return $logData
}

function Analyze-APRebootEvents {
    param([array]$LogLines, [string]$AnalysisMode)
    
    Write-ColorOutput "[INFO] Analyzing AP reboot/restart events..." "Cyan"
    
    $rebootEvents = @()
    $rebootIndicators = @()
    
    foreach ($line in $LogLines) {
        if ($AnalysisMode -eq "Quick") {
            # Quick mode: Look for low remotewtptime values (under 30 seconds)
            if ($line -match 'remotewtptime="([0-9]{1,2}\.[0-9]+)"' -and [double]$matches[1] -lt 30) {
                if ($line -match 'date=([^\s]+)\s+time=([^\s]+).*ap="([^"]+)".*msg="([^"]+)"') {
                    $rebootIndicators += @{
                        DateTime = "$($matches[1]) $($matches[2])"
                        AP = $matches[3]
                        Uptime = [double]$matches[1]
                        Message = $matches[4]
                        RawLine = $line
                    }
                }
            }
        } else {
            # Detailed mode: More precise analysis
            $logData = Parse-FortiLogLine $line
            
            # Look for remotewtptime = 0.0 or very low values, excluding authentication events
            if ($logData.remotewtptime -and 
                ([double]$logData.remotewtptime -eq 0.0 -or [double]$logData.remotewtptime -lt 10.0) -and 
                $logData.action -notmatch "RADIUS|auth|OKC|invalid.*MIC") {
                
                $rebootEvents += @{
                    DateTime = "$($logData.date) $($logData.time)"
                    Device = $logData.devname
                    AP = $logData.ap
                    Uptime = $logData.remotewtptime
                    Message = $logData.msg
                    Action = $logData.action
                    RawLine = $line
                }
            }
        }
    }
    
    if ($AnalysisMode -eq "Quick") {
        # Group reboot events by time to identify actual reboots (Quick mode)
        $rebootTimes = @()
        $lastRebootTime = $null
        
        foreach ($event in ($rebootIndicators | Sort-Object DateTime)) {
            try {
                $currentTime = [DateTime]::ParseExact($event.DateTime, "yyyy-MM-dd HH:mm:ss", $null)
                
                # If this is more than 1 hour from last reboot, it's a new reboot
                if (-not $lastRebootTime -or ($currentTime - $lastRebootTime).TotalHours -gt 1) {
                    $rebootTimes += $event
                    $lastRebootTime = $currentTime
                }
            } catch {
                # Skip invalid dates
            }
        }
        return $rebootTimes
    } else {
        return $rebootEvents
    }
}

function Analyze-InfrastructureEvents {
    param([array]$LogLines)
    
    Write-ColorOutput "[INFO] Analyzing infrastructure events..." "Cyan"
    
    $infraEvents = @()
    
    # Patterns that indicate infrastructure issues (excluding common DNS failures)
    $infraPatterns = @(
        'wtp.*join',
        'wtp.*leave', 
        'ap.*join',
        'ap.*leave',
        'ap.*offline',
        'ap.*online',
        'controller',
        'capwap',
        'tunnel',
        'session.*down',
        'session.*up',
        'power',
        'hardware',
        'reboot',
        'restart',
        'boot',
        'lost.*connection',
        'connection.*lost',
        'timeout',
        'unreachable'
    )
    
    foreach ($line in $LogLines) {
        # Skip common DNS failures that aren't infrastructure issues
        if ($line -match 'DNS.*failed.*non-existing domain|DNS.*failed.*server failure') {
            continue
        }
        
        foreach ($pattern in $infraPatterns) {
            if ($line -match $pattern) {
                $logData = Parse-FortiLogLine $line
                $infraEvents += @{
                    DateTime = "$($logData.date) $($logData.time)"
                    Device = $logData.devname
                    AP = $logData.ap
                    Level = $logData.level
                    Action = $logData.action
                    Message = $logData.msg
                    Pattern = $pattern
                    RawLine = $line
                }
                break
            }
        }
    }
    
    return $infraEvents
}

function Analyze-ExcessiveFrameFailures {
    param([array]$LogLines)
    
    Write-ColorOutput "[INFO] Analyzing RF issues and frame failures..." "Cyan"
    
    $frameFailures = @()
    
    foreach ($line in $LogLines) {
        if ($line -match "client-disconnected-by-wtp.*excessive.*frames") {
            $logData = Parse-FortiLogLine $line
            $frameFailures += @{
                DateTime = "$($logData.date) $($logData.time)"
                Device = $logData.devname
                AP = $logData.ap
                ClientMAC = $logData.stamac
                Message = $logData.msg
                RawLine = $line
            }
        }
    }
    
    return $frameFailures
}

function Generate-Recommendations {
    param($Results, [string]$Mode)
    
    $recommendations = @()
    
    if ($Results.RebootEvents.Count -gt 0) {
        $recommendations += "[CRITICAL] AP Reboots Detected: $($Results.RebootEvents.Count) reboot events found."
        $recommendations += "   - Check for scheduled maintenance windows"
        $recommendations += "   - Verify power supply stability"
        $recommendations += "   - Review recent firmware updates"
        $recommendations += "   - Check controller-initiated restarts"
    }
    
    if ($Results.FrameFailures.Count -gt 10) {
        $recommendations += "[WARNING] High RF Issues: $($Results.FrameFailures.Count) frame failures detected."
        $recommendations += "   - Check RF environment for interference"
        $recommendations += "   - Verify antenna connections and positioning"
        $recommendations += "   - Consider channel optimization"
        $recommendations += "   - Check AP hardware health"
    } elseif ($Results.FrameFailures.Count -gt 0) {
        $recommendations += "[INFO] Moderate RF Issues: $($Results.FrameFailures.Count) frame failures detected."
        $recommendations += "   - Monitor signal quality trends"
        $recommendations += "   - Check for intermittent interference"
    }
    
    if ($Results.InfrastructureEvents.Count -gt 0) {
        $recommendations += "[INFO] Infrastructure Events: $($Results.InfrastructureEvents.Count) events found."
        $recommendations += "   - Review controller connectivity"
        $recommendations += "   - Check network infrastructure health"
        $recommendations += "   - Verify CAPWAP tunnel stability"
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "[OK] No significant infrastructure issues detected."
        $recommendations += "   - AP appears to be functioning normally"
        $recommendations += "   - Continue regular monitoring"
    }
    
    return $recommendations
}

function Export-DetailedReport {
    param($Results, $OutputPath, $LogPath)
    
    $reportContent = @"
# FortiAnalyzer AP/Switch Analysis Report
Generated: $(Get-Date)
Log File: $LogPath
Analysis Mode: Detailed

## Executive Summary
- AP Reboot Events: $($Results.RebootEvents.Count)
- Infrastructure Events: $($Results.InfrastructureEvents.Count)  
- RF Frame Failures: $($Results.FrameFailures.Count)

## AP Reboot Events
$($Results.RebootEvents | ForEach-Object { "- $($_.DateTime): $($_.AP) - $($_.Message)" } | Out-String)

## Infrastructure Events (Top 20)
$($Results.InfrastructureEvents | Select-Object -First 20 | ForEach-Object { "- $($_.DateTime): $($_.Device) [$($_.Pattern)] - $($_.Message)" } | Out-String)

## RF Frame Failures (Top 20)
$($Results.FrameFailures | Select-Object -First 20 | ForEach-Object { "- $($_.DateTime): $($_.AP) - Client $($_.ClientMAC)" } | Out-String)

## Recommendations
$($Results.Recommendations | ForEach-Object { $_ } | Out-String)

## Analysis Details
Total log lines processed: $($Results.Summary.TotalLines)
Analysis completed: $(Get-Date)
"@

    $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-ColorOutput "[REPORT] Detailed report saved to: $OutputPath" "Green"
}

function Display-QuickResults {
    param($Results)
    
    Write-ColorOutput ("`n" + "="*60) "White"
    Write-ColorOutput "[RESULTS] AP STATUS SUMMARY" "Green"
    Write-ColorOutput ("="*60) "White"
    
    # Reboot Events
    $rebootColor = if ($Results.RebootEvents.Count -gt 0) { "Red" } else { "Green" }
    Write-ColorOutput "`n[REBOOTS] Detected AP Reboots: $($Results.RebootEvents.Count)" $rebootColor
    
    foreach ($reboot in $Results.RebootEvents) {
        Write-ColorOutput "  - $($reboot.DateTime): $($reboot.AP)" "Yellow"
        Write-ColorOutput "    $($reboot.Message)" "Gray"
    }
    
    # Frame Failures
    $rfColor = if ($Results.FrameFailures.Count -gt 10) { "Red" } elseif ($Results.FrameFailures.Count -gt 0) { "Yellow" } else { "Green" }
    Write-ColorOutput "`n[RF ISSUES] Frame Failures: $($Results.FrameFailures.Count)" $rfColor
    
    if ($Results.FrameFailures.Count -gt 0) {
        $groupedFailures = $Results.FrameFailures | Group-Object AP | Sort-Object Count -Descending
        foreach ($group in ($groupedFailures | Select-Object -First 5)) {
            Write-ColorOutput "  - AP: $($group.Name) - $($group.Count) failures" "White"
        }
    }
    
    # Infrastructure Events (if requested)
    if ($ShowInfraEvents -and $Results.InfrastructureEvents.Count -gt 0) {
        Write-ColorOutput "`n[INFRASTRUCTURE] Events: $($Results.InfrastructureEvents.Count)" "Yellow"
        foreach ($event in ($Results.InfrastructureEvents | Select-Object -First 5)) {
            Write-ColorOutput "  - $($event.DateTime): $($event.Pattern)" "Gray"
        }
    }
    
    # Recommendations
    Write-ColorOutput "`n[RECOMMENDATIONS]" "Cyan"
    foreach ($rec in $Results.Recommendations) {
        $color = if ($rec.StartsWith("[CRITICAL]")) { "Red" } elseif ($rec.StartsWith("[WARNING]")) { "Yellow" } elseif ($rec.StartsWith("[OK]")) { "Green" } else { "Cyan" }
        Write-ColorOutput "  $rec" $color
    }
}

function Display-DetailedResults {
    param($Results)
    
    Write-ColorOutput ("`n" + "="*80) "White"
    Write-ColorOutput "[RESULTS] DETAILED ANALYSIS RESULTS" "Green"
    Write-ColorOutput ("="*80) "White"
    
    # Reboot Events
    Write-ColorOutput "`n[REBOOT] AP REBOOT EVENTS ($($Results.RebootEvents.Count))" "Yellow"
    if ($Results.RebootEvents.Count -gt 0) {
        foreach ($event in ($Results.RebootEvents | Select-Object -First $MaxEvents)) {
            Write-ColorOutput "   [TIME] $($event.DateTime)" "White"
            Write-ColorOutput "   [DEVICE] Device: $($event.Device), AP: $($event.AP)" "Gray"
            Write-ColorOutput "   [UPTIME] $($event.Uptime)s, Action: $($event.Action)" "Gray"
            Write-ColorOutput "   [MSG] $($event.Message)" "Cyan"
            Write-ColorOutput "" "White"
        }
        if ($Results.RebootEvents.Count -gt $MaxEvents) {
            Write-ColorOutput "   ... and $($Results.RebootEvents.Count - $MaxEvents) more reboot events" "Gray"
        }
    } else {
        Write-ColorOutput "   [OK] No AP reboot events detected" "Green"
    }
    
    # Infrastructure Events
    Write-ColorOutput "`n[INFRA] INFRASTRUCTURE EVENTS ($($Results.InfrastructureEvents.Count))" "Yellow"
    if ($Results.InfrastructureEvents.Count -gt 0) {
        foreach ($event in ($Results.InfrastructureEvents | Select-Object -First $MaxEvents)) {
            Write-ColorOutput "   [TIME] $($event.DateTime)" "White"
            Write-ColorOutput "   [DEVICE] Device: $($event.Device), Pattern: $($event.Pattern)" "Gray"
            Write-ColorOutput "   [MSG] $($event.Message)" "Cyan"
            Write-ColorOutput "" "White"
        }
        if ($Results.InfrastructureEvents.Count -gt $MaxEvents) {
            Write-ColorOutput "   ... and $($Results.InfrastructureEvents.Count - $MaxEvents) more infrastructure events" "Gray"
        }
    } else {
        Write-ColorOutput "   [OK] No infrastructure events detected" "Green"
    }
    
    # Frame Failures
    Write-ColorOutput "`n[RF] FRAME FAILURE EVENTS ($($Results.FrameFailures.Count))" "Yellow"
    if ($Results.FrameFailures.Count -gt 0) {
        $groupedFailures = $Results.FrameFailures | Group-Object AP | Sort-Object Count -Descending
        foreach ($group in $groupedFailures) {
            Write-ColorOutput "   [AP] $($group.Name): $($group.Count) failures" "White"
        }
        
        Write-ColorOutput "`n   [RECENT FAILURES]" "Gray"
        foreach ($failure in ($Results.FrameFailures | Select-Object -First 5)) {
            Write-ColorOutput "   - $($failure.DateTime): Client $($failure.ClientMAC)" "Gray"
        }
    } else {
        Write-ColorOutput "   [OK] No excessive frame failures detected" "Green"
    }
    
    # Recommendations
    Write-ColorOutput "`n[RECOMMENDATIONS]" "Yellow"
    foreach ($rec in $Results.Recommendations) {
        $color = if ($rec.StartsWith("[CRITICAL]")) { "Red" } elseif ($rec.StartsWith("[WARNING]")) { "Yellow" } elseif ($rec.StartsWith("[OK]")) { "Green" } else { "Cyan" }
        Write-ColorOutput "   $rec" $color
    }
}

# Main execution
try {
    $modeText = if ($Mode -eq "Quick") { "QUICK" } else { "DETAILED" }
    Write-ColorOutput "[START] FortiAnalyzer AP Analyzer - $modeText MODE" "Green"
    Write-ColorOutput "[PATH] Log Path: $LogPath" "Yellow"
    
    # Get log files
    $logFiles = @()
    if (Test-Path $LogPath -PathType Container) {
        $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" | Select-Object -ExpandProperty FullName
    } elseif (Test-Path $LogPath -PathType Leaf) {
        $logFiles = @($LogPath)
    } else {
        throw "Log path not found: $LogPath"
    }
    
    Write-ColorOutput "[FILES] Found $($logFiles.Count) log file(s) to analyze" "Yellow"
    
    # Read log files
    $allLogLines = @()
    foreach ($file in $logFiles) {
        Write-ColorOutput "[READ] Reading: $(Split-Path $file -Leaf)" "Gray"
        $content = Get-Content -Path $file
        $allLogLines += $content
    }
    
    Write-ColorOutput "[LINES] Total log lines: $($allLogLines.Count)" "Yellow"
    
    # Filter by device name if specified
    if ($DeviceName) {
        $allLogLines = $allLogLines | Where-Object { $_ -match "devname=`"$DeviceName`"" }
        Write-ColorOutput "[FILTER] Filtered to device '$DeviceName': $($allLogLines.Count) lines" "Yellow"
    }
    
    # Perform analysis
    $AnalysisResults.RebootEvents = Analyze-APRebootEvents $allLogLines $Mode
    $AnalysisResults.FrameFailures = Analyze-ExcessiveFrameFailures $allLogLines
    
    # Only analyze infrastructure events if in detailed mode or explicitly requested
    if ($Mode -eq "Detailed" -or $ShowInfraEvents) {
        $AnalysisResults.InfrastructureEvents = Analyze-InfrastructureEvents $allLogLines
    }
    
    $AnalysisResults.Recommendations = Generate-Recommendations $AnalysisResults $Mode
    $AnalysisResults.Summary.TotalLines = $allLogLines.Count
    
    # Display results based on mode
    if ($Mode -eq "Quick") {
        Display-QuickResults $AnalysisResults
    } else {
        Display-DetailedResults $AnalysisResults
        
        # Generate detailed report if requested
        if ($OutputPath -or $Mode -eq "Detailed") {
            if (-not $OutputPath) {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $logDir = if (Test-Path $LogPath -PathType Container) { $LogPath } else { Split-Path $LogPath -Parent }
                if (-not $logDir) { $logDir = "." }
                $OutputPath = Join-Path $logDir "AP_Analysis_Report_$timestamp.txt"
            }
            Export-DetailedReport $AnalysisResults $OutputPath $LogPath
        }
    }
    
    Write-ColorOutput "`n[SUCCESS] Analysis completed successfully!" "Green"
    
} catch {
    Write-ColorOutput "[ERROR] Error during analysis: $($_.Exception.Message)" "Red"
    if ($Mode -eq "Detailed") {
        Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    }
}