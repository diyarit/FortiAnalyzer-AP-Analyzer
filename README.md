# FortiAnalyzer AP Analyzer

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://github.com/PowerShell/PowerShell#get-powershell)
[![Version](https://img.shields.io/badge/Version-3.1.0-blue.svg)](CHANGELOG.md)
[![Tests](https://img.shields.io/badge/Tests-31%20passing-brightgreen.svg)](tests/)

A powerful PowerShell tool that analyzes FortiAnalyzer logs to quickly identify when and why Access Points (APs), switches, or infrastructure components went offline. Supports **100+ event types** across system, HA, wireless, switch, SD-WAN, VPN, router, and user categories.

## What It Does

- **Detects AP Reboots**: Advanced `remotewtptime` heuristic analysis to identify when APs restart
- **Identifies RF Issues**: Finds excessive frame failures and signal quality problems
- **Discovers Infrastructure Problems**: Locates controller, CAPWAP, hardware, and HA issues
- **Tracks VPN/SD-WAN**: Monitors tunnel status, SLA failures, and ISP link health
- **Multiple Export Formats**: HTML (styled dark-theme dashboard), JSON, CSV, and text reports
- **Time Range Filtering**: Analyze events within specific time windows
- **Log Level Filtering**: Filter by severity (critical, warning, notice, etc.)
- **Customizable Thresholds**: Adjust detection sensitivity for your environment
- **Pipeline Support**: `-Quiet` mode returns structured objects for automation

## Quick Start

```powershell
# Daily monitoring (default Quick mode)
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-wireless.log"

# Detailed investigation with HTML report
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-wireless.log" -Mode Detailed

# Filter specific device with time range
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -DeviceName "AP-01" -StartTime (Get-Date).AddDays(-7)

# Export as JSON for automation
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -Mode Detailed -OutputFormat JSON -OutputPath report.json

# Quiet mode for pipeline use
$results = .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -Quiet
$results.WirelessEvents | Where-Object { $_.Severity -eq 'Critical' }

# Minimum severity filter
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -LogLevel warning -Mode Detailed

# Custom thresholds
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -RebootThreshold 60 -HighRFThreshold 50
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `LogPath` | String | *Required* | Path to log file or directory |
| `Mode` | String | `Quick` | `Quick` (dashboard) or `Detailed` (full report) |
| `DeviceName` | String | - | Filter to specific device hostname |
| `StartTime` | DateTime | - | Only include events at or after this time |
| `EndTime` | DateTime | - | Only include events at or before this time |
| `LogLevel` | String | - | Minimum severity: emergency, alert, critical, error, warning, notice, information, debug |
| `MaxEvents` | Int | `10` | Max events per category in Detailed mode |
| `RebootThreshold` | Double | `30` | Max remotewtptime (seconds) to flag as reboot |
| `HighRFThreshold` | Int | `20` | Frame failure count triggering HIGH RF warning |
| `OutputFormat` | String | Auto | Export format: Text, HTML, JSON, CSV |
| `OutputPath` | String | Auto | Report output path (auto-generated if omitted) |
| `ShowAllEvents` | Switch | False | Show all events (not just top N) |
| `Quiet` | Switch | False | Suppress console output, return pipeline objects |

## Sample Output

### Quick Mode (Dashboard)
```
======================================================================
  FORTIANALYZER INFRASTRUCTURE DASHBOARD
======================================================================
  [SYS] System/HA:    CRITICAL (3 events)
  [SWI] Switch:       HEALTHY (0 events)
  [WLS] Wireless:     WARNING (5 events)
  [SDW] SD-WAN:       HEALTHY (0 events)
  [HWR] Hardware:     CRITICAL (1 events)
  [VPN] VPN:          HEALTHY (0 events)
  [RTR] Router:       HEALTHY (0 events)
  [USR] User:         HEALTHY (0 events)
  [RF ] RF Health:    WARNING (8 failures)
======================================================================

  RECOMMENDATIONS
----------------------------------------------------------------------
    [Critical] SYSTEM CRASH: 1 watchdog reset(s) detected.
    [Critical] HARDWARE: 1 fan/temperature alarm(s).
    [Warning] RF QUALITY: 8 frame failure(s).
```

### Detailed Mode
Full event breakdown per category with timestamps, severity, source, and message. Auto-generates an HTML report with:
- Dark-themed dashboard with summary cards
- Color-coded recommendations
- Sortable event table (top 200)

### GUI (Enterprise)
- 8 dashboard status cards with real-time severity indicators
- 8 event tabs: System/HA, Switch, Wireless, SD-WAN, VPN, Router, Frame Failures, Raw Logs
- Time range and log level filter controls
- Export to HTML/JSON/CSV/Text
- Keyboard shortcuts: F5 (analyze), Ctrl+S (export), Escape (close)

## Event Coverage (100+ Log IDs)

| Category | Count | Key Events |
|----------|-------|------------|
| **System** | 22 | System started/shutdown/crash, conserve mode, disk low, interface down/up, NTP sync |
| **HA** | 18 | Heartbeat lost/restored, failover success/failed, sync failed, monitor interface down, priority changed |
| **Hardware** | 2 | Fan failure, temperature high (overheat) |
| **Wireless** | 36 | AP joined/left/rebooted, CAPWAP tunnel down, radar detected, rogue AP, firmware upgrade failed, radio interference, DFS |
| **Switch** | 21 | Switch online/offline, PoE error/budget exceeded, STP topology change, port security violation, VLAN changed, LLDP |
| **SD-WAN** | 13 | SLA failed, member down/up, health check failed, virtual WAN link status |
| **VPN** | 12 | IPsec tunnel up/down, SSL VPN login failed, Phase 1/2 established/failed |
| **Router** | 9 | BGP/OSPF neighbor down, static route added/removed, DHCP lease, DNS query failed |
| **User** | 10 | Login success/failed, user locked out, password expired, session timeout |

## Architecture

```
FortiAnalyzer-AP-Analyzer/
├── src/
│   └── FortiAnalyzer.Core.psm1        # Shared module (parsing, 100+ events, analysis, export)
├── FortiAnalyzer-AP-Analyzer.ps1      # CLI tool (v3.1.0)
├── FortiAnalyzer-AP-Analyzer-GUI.ps1  # WPF GUI (v3.1.0 Enterprise)
├── tests/
│   └── FortiAnalyzer.Core.Tests.ps1   # 31 Pester tests
├── examples/
│   └── sample-log-entries.txt          # Sample FortiAnalyzer log entries
├── docs/
├── .github/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── PROJECT_STRUCTURE.md
```

### Core Module (`src/FortiAnalyzer.Core.psm1`)
The shared engine used by both CLI and GUI. Contains:
- **Compiled regex** for high-performance parsing (created once, reused per line)
- **100+ event definitions** across 9 categories
- `ConvertFrom-FortiLogLine` - Parse any FortiAnalyzer log line
- `Get-FortiAnalysisResults` - Unified analysis with time/device/level filtering
- `New-FortiRecommendation` - Actionable recommendations engine
- `Export-FortiReport` - Multi-format export (Text, HTML, JSON, CSV)

## Testing

```powershell
# Run all tests
Invoke-Pester -Script ./tests/FortiAnalyzer.Core.Tests.ps1

# Install Pester if needed
Install-Module Pester -Force -SkipPublisherCheck
```

**31 tests** covering:
- Log line parsing (quoted/unquoted values, complex fields)
- Event definition lookup (100+ log IDs)
- AP reboot detection (exact `remotewtptime=0.0` and heuristic low-uptime)
- Frame failure detection
- Device name filtering
- Time range filtering
- Recommendation generation (Critical, Warning, OK scenarios)
- Report export (JSON, CSV, HTML, Text)

## Installation

### Prerequisites
- PowerShell 5.1+
- Access to FortiAnalyzer wireless/system event logs

### Download
```bash
git clone https://github.com/diyarit/fortianalyzer-ap-analyzer.git
cd fortianalyzer-ap-analyzer
```

### Execution Policy (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Integration Examples

```powershell
# Daily scheduled task with email alerts
$results = .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "\\server\logs\latest.log" -Quiet
$critical = $results.SystemEvents | Where-Object { $_.Severity -eq 'Critical' }
if ($critical) {
    Send-MailMessage -To "noc@company.com" -Subject "FortiAnalyzer Alerts" -Body ($critical | Out-String)
}

# Batch process multiple devices
Get-ChildItem "C:\Logs\*.log" | ForEach-Object {
    Write-Host "Analyzing: $($_.Name)" -ForegroundColor Yellow
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath $_.FullName -Mode Detailed
}

# Export HTML for web dashboard
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -Mode Detailed -OutputFormat HTML -OutputPath "C:\WebRoot\report.html"

# Analyze last 24 hours, critical events only
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -StartTime (Get-Date).AddDays(-1) -LogLevel critical -Mode Detailed

# Compare reboot counts across devices
$devices = @("FW-01", "FW-02", "FW-03")
foreach ($dev in $devices) {
    $r = .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -DeviceName $dev -Quiet
    $reboots = ($r.WirelessEvents | Where-Object { $_.Desc -match 'Reboot' }).Count
    Write-Host "$dev : $reboots reboots" -ForegroundColor $(if ($reboots -gt 0) { 'Red' } else { 'Green' })
}
```

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| **3.1.0** | 2026-06-20 | Shared core module, 100+ events, multi-format export, time/level filtering, 31 Pester tests |
| **3.0.0** | 2025-10-20 | WPF GUI, enterprise dashboard, expanded event coverage |
| **2.0.0** | 2025-10-20 | Unified CLI tool, Quick/Detailed modes |
| **1.0.0** | 2025-10-20 | Initial release |

See [CHANGELOG.md](CHANGELOG.md) for full details.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- [Usage Guide](AP-Analyzer-Usage-Guide.md) | [Quick Reference](Quick-Reference.md) | [Project Structure](PROJECT_STRUCTURE.md)
- [GitHub Issues](../../issues) for bug reports and feature requests

---

**Built by network engineers, for network engineers.**
