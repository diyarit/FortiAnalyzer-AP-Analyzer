# Project Structure

```
FortiAnalyzer-AP-Analyzer/
├── src/
│   └── FortiAnalyzer.Core.psm1          # Core module (parsing, events, analysis, export)
├── FortiAnalyzer-AP-Analyzer.ps1        # CLI tool (v3.0)
├── FortiAnalyzer-AP-Analyzer-GUI.ps1    # WPF GUI (v3.0 Enterprise)
├── tests/
│   └── FortiAnalyzer.Core.Tests.ps1     # 31 Pester tests
├── examples/
│   └── sample-log-entries.txt            # Sample FortiAnalyzer log entries
├── docs/
├── .github/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── PROJECT_STRUCTURE.md
└── Quick-Reference.md
```

## Core Files

### `src/FortiAnalyzer.Core.psm1` (Shared Module)
The centralized module used by both CLI and GUI. Contains:
- **Compiled regex patterns** for high-performance parsing
- **100+ event definitions** across 9 categories (System, HA, Hardware, Wireless, Switch, SD-WAN, VPN, Router, User)
- **ConvertFrom-FortiLogLine** - Parse any FortiAnalyzer log line
- **Get-FortiAnalysisResults** - Unified analysis with time/device/level filtering
- **New-FortiRecommendation** - Actionable recommendations engine
- **Export-FortiReport** - Multi-format export (Text, HTML, JSON, CSV)
- **Write-FortiDashboard** - Console dashboard output

### `FortiAnalyzer-AP-Analyzer.ps1` (CLI Tool)
Full-featured command-line tool with:
- `[CmdletBinding()]` with parameter validation
- Pipeline input support (`ValueFromPipeline`)
- `-Quiet` mode for automation
- Time range and log level filtering
- Customizable thresholds (`-RebootThreshold`, `-HighRFThreshold`)

### `FortiAnalyzer-AP-Analyzer-GUI.ps1` (WPF GUI)
Enterprise-grade WPF interface with:
- 8 dashboard status cards (System, Switch, Wireless, RF, SD-WAN, Hardware, VPN, Router)
- 8 event detail tabs
- Time range and log level filter controls
- Multi-format export (HTML/JSON/CSV/Text)
- Keyboard shortcuts (F5, Ctrl+S, Escape)

### `tests/FortiAnalyzer.Core.Tests.ps1`
31 Pester v3 tests covering:
- Log line parsing (quoted/unquoted values, complex fields)
- Event definition lookup
- AP reboot detection (exact and heuristic)
- Frame failure detection
- Device and time filtering
- Recommendation generation
- Report export (JSON, CSV, HTML, Text)

## Key Improvements in v3.0

| Area | v2.x | v3.0 |
|------|------|------|
| **Architecture** | Monolithic scripts, duplicated logic | Shared Core module, single source of truth |
| **Event Coverage** | 22 log IDs | 100+ log IDs across 9 categories |
| **Performance** | Array += anti-pattern, recompiled regex | List<T>, compiled regex, streaming I/O |
| **Export** | Plain text only | HTML, JSON, CSV, Text |
| **Filtering** | Device name only | Device, time range, log level |
| **Testing** | None | 31 Pester tests |
| **Code Quality** | No CmdletBinding, non-standard verbs | CmdletBinding, approved verbs, validation |
| **GUI** | 6 tabs, incomplete export | 8 tabs, complete export, keyboard shortcuts |
