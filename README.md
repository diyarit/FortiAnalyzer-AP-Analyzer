# FortiAnalyzer AP Analyzer

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://github.com/PowerShell/PowerShell#get-powershell)

A powerful PowerShell tool that analyzes FortiAnalyzer wireless logs to quickly identify when and why Access Points (APs) or switches go offline. Cut through thousands of log lines in seconds to find the root cause of network infrastructure issues.

## 🎯 What It Does

- **Detects AP Reboots**: Uses advanced `remotewtptime` analysis to identify when APs restart
- **Identifies RF Issues**: Finds excessive frame failures and signal quality problems  
- **Discovers Infrastructure Problems**: Locates controller, CAPWAP, and hardware issues
- **Filters Noise**: Focuses on infrastructure events, not client connectivity issues
- **Two Analysis Modes**: Quick daily monitoring or detailed investigation
- **Smart Recommendations**: Provides actionable troubleshooting steps

## 🚀 Quick Start

```powershell
# Daily monitoring (30 seconds)
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-wireless.log"

# Detailed investigation (1-2 minutes)  
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "fortianalyzer-wireless.log" -Mode Detailed

# Filter specific device
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -DeviceName "AP-01" -Mode Detailed
```

## 📊 Sample Output

### Quick Mode (Default)
```
============================================================
[RESULTS] AP STATUS SUMMARY
============================================================

[REBOOTS] Detected AP Reboots: 0

[RF ISSUES] Frame Failures: 29
  - AP: AP-WL-AP01 - 29 failures

[RECOMMENDATIONS]
  [WARNING] High RF Issues: 29 frame failures detected.
     - Check RF environment for interference
     - Verify antenna connections and positioning
     - Consider channel optimization
     - Check AP hardware health
```

### Detailed Mode
```
================================================================================
[RESULTS] DETAILED ANALYSIS RESULTS
================================================================================

[REBOOT] AP REBOOT EVENTS (2)
   [TIME] 2025-10-20 04:52:19
   [DEVICE] Device: AP-WL-01, AP: AP-WL-AP01
   [UPTIME] 1.703817s, Action: DNS-no-domain
   [MSG] DNS lookup failed - indicates recent reboot

[INFRA] INFRASTRUCTURE EVENTS (15)
   [TIME] 2025-10-18 21:18:16
   [DEVICE] Device: BSC-WL-01, Pattern: power
   [MSG] AP AP-WL-AP01 radio 2 found radar pulse, change channel

[RF] FRAME FAILURE EVENTS (29)
   [AP] AP-WL-AP01: 29 failures
   
   [RECENT FAILURES]
   - 2025-10-20 05:15:12: Client 66:a2:bb:c6:D4:4D
   - 2025-10-20 04:26:57: Client e2:79:e9:94:6F:b4
```

## 🛠️ Installation

### Prerequisites
- **PowerShell 5.1+** (Windows) or **PowerShell Core 6.0+** (Linux/macOS)
- Access to FortiAnalyzer wireless event logs
- Read permissions on log files

### Download
```bash
git clone https://github.com/diyarit/fortianalyzer-ap-analyzer.git
cd fortianalyzer-ap-analyzer
```

### PowerShell Execution Policy (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📖 Usage

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `LogPath` | String | ✅ | - | Path to log file or directory |
| `Mode` | String | ❌ | Quick | Analysis mode: `Quick` or `Detailed` |
| `DeviceName` | String | ❌ | - | Filter to specific device (e.g., "AP-01") |
| `ShowInfraEvents` | Switch | ❌ | False | Show infrastructure events in Quick mode |
| `OutputPath` | String | ❌ | Auto | Custom report file path (Detailed mode) |
| `MaxEvents` | Int | ❌ | 10 | Maximum events to display per category |

### Examples

#### Daily Monitoring
```powershell
# Quick health check (recommended for daily use)
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "\\server\logs\wireless-today.log"

# Include infrastructure events
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "wireless.log" -ShowInfraEvents
```

#### Incident Investigation
```powershell
# Deep analysis of specific AP
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "incident-logs\" -Mode Detailed -DeviceName "PROBLEM-AP"

# Generate custom report
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "logs\" -Mode Detailed -OutputPath "C:\Reports\AP-Analysis.txt"
```

#### Batch Processing
```powershell
# Analyze multiple log files
Get-ChildItem "C:\Logs\*.log" | ForEach-Object {
    Write-Host "Analyzing: $($_.Name)" -ForegroundColor Yellow
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath $_.FullName
}
```

## 🔍 What It Detects

### 🔄 AP Reboots
- **Quick Mode**: Identifies reboots using 30-second uptime threshold
- **Detailed Mode**: Precise analysis using `remotewtptime=0.0` and low uptime values
- **Smart Filtering**: Excludes false positives from authentication events

### 📡 RF Issues  
- Excessive frame acknowledgment failures
- Client disconnections due to poor RF conditions
- Signal quality degradation
- Channel interference problems

### 🏗️ Infrastructure Events
- Controller connectivity issues
- CAPWAP tunnel problems
- Hardware failures and power issues
- WTP join/leave events
- Radar detection and channel changes

## 🎯 Mode Comparison

| Feature | Quick Mode | Detailed Mode |
|---------|------------|---------------|
| **Analysis Time** | ~30 seconds | 1-2 minutes |
| **AP Reboot Detection** | Basic (30s threshold) | Advanced (precise analysis) |
| **Infrastructure Events** | Optional (`-ShowInfraEvents`) | Always included |
| **Report Generation** | Console only | Console + File report |
| **Event Details** | Summary view | Full event details |
| **Best For** | Daily monitoring | Incident investigation |

## 🚨 Alert Levels

| Level | Color | Meaning | Action Required |
|-------|-------|---------|-----------------|
| **[CRITICAL]** | 🔴 Red | AP reboots detected | Immediate investigation |
| **[WARNING]** | 🟡 Yellow | High RF issues (>10 failures) | Monitor and plan fixes |
| **[INFO]** | 🔵 Cyan | Moderate issues or events | Routine monitoring |
| **[OK]** | 🟢 Green | No issues detected | Continue monitoring |

## 📋 Log Format Support

The tool supports FortiAnalyzer wireless event logs with these fields:
- `date=` and `time=` - Event timestamp
- `devname=` - Device name
- `ap=` - Access Point name  
- `remotewtptime=` - AP uptime (key for reboot detection)
- `msg=` - Event message
- `action=` - Event action type
- `stamac=` - Client MAC address
- `reason=` - Disconnection reason

### Sample Log Entry
```
date=2025-10-20 time=04:52:19 devname="AP-WL-01" ap="AP-WL-AP01" 
remotewtptime="1.703817" action="DNS-no-domain" 
msg="DNS lookup of wpad.grenergy.local from client failed"
```

## ⚡ Performance

- **Quick Mode**: Processes 30,000+ log lines in ~30 seconds
- **Detailed Mode**: Processes 30,000+ log lines in 1-2 minutes  
- **Memory Efficient**: Handles large files without excessive RAM usage
- **Progress Tracking**: Visual feedback during processing

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Log path not found" | Verify file path and read permissions |
| "No events detected" | Check log format or try different time period |
| Slow performance | Use `-DeviceName` filter or Quick mode |
| Missing AP names | Verify AP field is populated in logs |

### Getting Help

1. Check the [Issues](../../issues) page for known problems
2. Review the [Usage Guide](AP-Analyzer-Usage-Guide.md) for detailed examples
3. See [Quick Reference](Quick-Reference.md) for parameter details

## 📁 Repository Structure

```
fortianalyzer-ap-analyzer/
├── FortiAnalyzer-AP-Analyzer.ps1    # Main analysis script
├── README.md                         # This file
├── AP-Analyzer-Usage-Guide.md        # Detailed usage guide
├── Quick-Reference.md                # Parameter quick reference
├── LICENSE                           # MIT license
└── examples/
    └── sample-logs/                  # Sample log files for testing
```

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow PowerShell best practices
- Add comments for complex logic
- Test with various log formats
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for network administrators tired of manually parsing FortiAnalyzer logs
- Inspired by real-world AP troubleshooting challenges
- Tested with FortiAnalyzer wireless event logs from various environments

## 📞 Support

- 📖 **Documentation**: [Usage Guide](AP-Analyzer-Usage-Guide.md) | [Quick Reference](Quick-Reference.md)
- 🐛 **Bug Reports**: [GitHub Issues](../../issues)
- 💡 **Feature Requests**: [GitHub Issues](../../issues)
- 📧 **Contact**: Create an issue for questions

---

**Built by network engineers, for network engineers.** Save time, find root causes faster, and keep your wireless infrastructure running smoothly.

⭐ **Star this repo** if it helped you solve AP offline issues!