# FortiAnalyzer AP Analyzer - Unified Tool Usage Guide

## 📋 What You Get

I've created **one unified PowerShell script** that handles both quick analysis and detailed investigation:

### **FortiAnalyzer-AP-Analyzer.ps1** (Unified Tool)
- **Quick Mode**: Fast 30-second analysis for daily monitoring
- **Detailed Mode**: Comprehensive analysis with full reporting
- **Smart Detection**: Identifies AP reboots, infrastructure events, and RF issues
- **Flexible Options**: Device filtering, custom reports, and configurable output
- **Color-coded Output**: Easy-to-read results with severity indicators

## 🚀 Quick Start

### For Daily Monitoring (Default - Quick Mode)
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "your-log-file.log"
```

### For Detailed Investigation
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "your-log-file.log" -Mode Detailed
```

### For Specific Device Analysis
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "your-log-file.log" -DeviceName "BSC-WL-AP01" -Mode Detailed
```

### Show Infrastructure Events in Quick Mode
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "your-log-file.log" -ShowInfraEvents
```

## 🔍 What The Scripts Detect

### ✅ **AP Reboot Detection**
- Uses `remotewtptime` analysis to identify when APs restart
- Filters out false positives (authentication events)
- Shows exact reboot timestamps

### ⚠️ **RF Issues**
- Excessive frame acknowledgment failures
- Client disconnections due to poor RF conditions
- Signal quality problems

### 🏗️ **Infrastructure Problems**
- Controller connectivity issues
- CAPWAP tunnel problems
- Hardware failures
- Power issues
- Network infrastructure problems

## 📊 Sample Output

```
============================================================
[RESULTS] AP STATUS SUMMARY
============================================================

[REBOOTS] Detected AP Reboots: 0

[RF ISSUES] Frame Failures: 29

[RECOMMENDATIONS]
  ! High RF issues detected - Check interference and antenna connections

[DONE] Quick check completed
```

## 🎯 Based on Your Log Analysis

From your specific log file, here's what we found:

### ✅ **Good News**
- **No AP reboots detected** during the log period
- AP stayed online and functional throughout
- Normal authentication and client connectivity

### ⚠️ **Areas to Monitor**
- **29 frame failure events** - indicates some RF interference
- Multiple DNS lookup failures (normal for missing domains)
- Some authentication failures (normal user behavior)

### 💡 **Recommendations for Your Environment**
1. **RF Environment**: Monitor channel 11 and 60 for interference
2. **Antenna Check**: Verify antenna connections on BSC-WL-AP01
3. **Channel Optimization**: Consider changing channels if interference persists
4. **Regular Monitoring**: Use the quick check script daily

## 🛠️ Advanced Usage

### Analyze Multiple Log Files
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "C:\Logs\" -Mode Detailed
```

### Generate Custom Reports
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -Mode Detailed -OutputPath "C:\Reports\MyReport.txt"
```

### Filter by Device with Custom Event Limit
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -DeviceName "AP-NAME" -Mode Detailed -MaxEvents 20
```

### Quick Check with Infrastructure Events
```powershell
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log.txt" -ShowInfraEvents
```

## 🔧 Troubleshooting

### Common Issues
- **"Log path not found"** → Check file path and permissions
- **"No events detected"** → Log may not contain infrastructure events
- **Slow performance** → Use device filtering for large files

### Performance Tips
- Use the Quick Check script for daily monitoring
- Filter by device name for faster analysis
- Process logs on SSD storage for better performance

## 📈 Integration Ideas

### Daily Monitoring
Create a scheduled task to run quick analysis daily:
```powershell
# Add to Windows Task Scheduler (Quick Mode is default)
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "\\server\logs\latest.log"
```

### Alert Integration
Modify the scripts to send email alerts when issues are detected.

### Batch Processing
Process multiple log files automatically:
```powershell
Get-ChildItem "C:\Logs\*.log" | ForEach-Object {
    Write-Host "Analyzing: $($_.Name)" -ForegroundColor Yellow
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath $_.FullName
}
```

## 🎯 Key Benefits

1. **Cuts Through Noise** - Focuses on infrastructure vs client issues
2. **Fast Analysis** - Processes 30K+ log lines in seconds
3. **Actionable Insights** - Provides specific recommendations
4. **Easy to Use** - Simple command-line interface
5. **Comprehensive** - Covers reboots, RF issues, and infrastructure problems

## 🎯 Mode Comparison

| Feature | Quick Mode | Detailed Mode |
|---------|------------|---------------|
| **Speed** | ~30 seconds | 1-2 minutes |
| **AP Reboot Detection** | Basic (30s threshold) | Advanced (precise analysis) |
| **Infrastructure Events** | Optional | Always included |
| **Report Generation** | Console only | Console + File |
| **Event Details** | Summary | Full details |
| **Best For** | Daily monitoring | Investigation |

## 📝 Next Steps

1. **Test the unified script** with your current log files
2. **Set up daily monitoring** using Quick Mode (default)
3. **Use Detailed Mode** when investigating specific issues
4. **Customize parameters** for your specific environment
5. **Integrate with your monitoring workflow**

The unified tool is ready to use and will help you quickly identify why APs go offline, saving you hours of manual log analysis!