# FortiAnalyzer AP Analyzer - Quick Reference

## 🚀 Basic Usage

```powershell
# Quick daily check (default)
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log-file.log"

# Detailed investigation
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log-file.log" -Mode Detailed

# Filter specific device
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "log-file.log" -DeviceName "AP-NAME"
```

## 📊 Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `-LogPath` | File/Directory | **Required** - Path to log file(s) |
| `-Mode` | Quick, Detailed | Analysis depth (default: Quick) |
| `-DeviceName` | String | Filter to specific device |
| `-ShowInfraEvents` | Switch | Show infrastructure events in Quick mode |
| `-OutputPath` | File path | Custom report location (Detailed mode) |
| `-MaxEvents` | Number | Max events per category (default: 10) |

## 🎯 What It Detects

### ✅ **AP Reboots**
- **Quick Mode**: Uses 30-second uptime threshold
- **Detailed Mode**: Precise `remotewtptime` analysis
- Filters out false positives (authentication events)

### ⚠️ **RF Issues**
- Excessive frame acknowledgment failures
- Client disconnections due to poor RF
- Signal quality problems

### 🏗️ **Infrastructure Events**
- Controller connectivity issues
- CAPWAP tunnel problems  
- Hardware/power events
- WTP join/leave events

## 📈 Output Examples

### Quick Mode Output
```
[REBOOTS] Detected AP Reboots: 0
[RF ISSUES] Frame Failures: 29
[RECOMMENDATIONS]
  [WARNING] High RF Issues: 29 frame failures detected.
```

### Detailed Mode Output
```
[REBOOT] AP REBOOT EVENTS (2)
   [TIME] 2025-10-20 04:52:19
   [DEVICE] Device: BSC-WL-01, AP: BSC-WL-AP01
   [UPTIME] 1.703817s, Action: DNS-no-domain
```

## 🔧 Common Use Cases

### Daily Monitoring
```powershell
# Run every morning
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "\\server\logs\latest.log"
```

### Incident Investigation
```powershell
# Deep dive analysis
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "incident-logs\" -Mode Detailed -DeviceName "PROBLEM-AP"
```

### Batch Analysis
```powershell
# Process multiple files
Get-ChildItem "*.log" | ForEach-Object {
    .\FortiAnalyzer-AP-Analyzer.ps1 -LogPath $_.FullName
}
```

## 🚨 Alert Levels

| Level | Color | Meaning |
|-------|-------|---------|
| **[CRITICAL]** | Red | AP reboots detected |
| **[WARNING]** | Yellow | High RF issues (>10 failures) |
| **[INFO]** | Cyan | Moderate issues or events |
| **[OK]** | Green | No issues detected |

## ⚡ Performance Tips

- **Quick Mode**: ~30 seconds for 30K lines
- **Detailed Mode**: ~1-2 minutes for 30K lines
- Use `-DeviceName` filter for faster processing
- Process logs on SSD for better performance
- Use Quick Mode for daily monitoring

## 🎯 Your Environment Results

Based on your log analysis:
- ✅ **No AP reboots** detected in recent logs
- ⚠️ **29 RF frame failures** - monitor interference
- 💡 **Recommendation**: Check channels 11 and 60 for interference

## 📞 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Log path not found" | Check file path and permissions |
| "No events detected" | Try different time period or mode |
| Slow performance | Use device filtering or Quick mode |
| Missing AP name | Check if AP field is populated in logs |