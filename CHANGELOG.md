# Changelog

All notable changes to the FortiAnalyzer AP Analyzer project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-06-20

### Added
- **Shared Core Module** (`src/FortiAnalyzer.Core.psm1`): Single source of truth for parsing, event definitions, analysis, and reporting used by both CLI and GUI
- **100+ Event Definitions**: Expanded from 22 to 100+ log IDs across 9 categories (System, HA, Hardware, Wireless, Switch, SD-WAN, VPN, Router, User)
- **Multi-Format Export**: HTML (styled dark-theme dashboard), JSON, CSV, and text reports
- **Time Range Filtering**: `-StartTime` and `-EndTime` parameters to narrow analysis windows
- **Log Level Filtering**: `-LogLevel` parameter to filter by minimum severity (emergency through debug)
- **Customizable Thresholds**: `-RebootThreshold` and `-HighRFThreshold` for environment-specific tuning
- **Quiet/Pipeline Mode**: `-Quiet` returns structured PSCustomObject for automation and scripting
- **Pester Test Suite**: 31 tests covering parsing, event detection, reboot heuristics, frame failures, filtering, recommendations, and export
- **GUI Tab Expansion**: Added VPN, Router, and Frame Failure tabs (8 total)
- **GUI Dashboard Cards**: Added VPN and Router status cards (8 total)
- **GUI Filter Controls**: Time range and log level filter UI elements
- **GUI Keyboard Shortcuts**: F5 (analyze), Ctrl+S (export), Escape (close)
- **Compiled Regex Patterns**: All regex compiled once at module load for high-performance parsing
- **`[CmdletBinding()]`**: Full parameter validation, pipeline input support, approved verb-noun naming

### Changed
- **Architecture**: Refactored from monolithic scripts to shared module pattern (CLI and GUI import `FortiAnalyzer.Core.psm1`)
- **Performance**: Replaced array `+=` with `[System.Collections.Generic.List[string]]`, streaming via `[System.IO.File]::ReadLines()`
- **Reboot Deduplication**: Uses `[HashSet[string]]` for O(1) duplicate detection instead of O(N) loop
- **Error Handling**: Granular `[ValidateScript()]`, `[ValidateRange()]`, `[ValidateSet()]` on all parameters
- **GUI Export**: Now exports all event categories (previously only System and Switch)
- **GUI Raw Logs**: Optimized with character limit to prevent TextBox rendering lag

### Fixed
- **PS 5.1 Compatibility**: Fixed `Join-Path` calls to use nested 2-argument form (PS 5.1 does not support 3+ arguments)
- **Parameter Validation**: `AllowEmptyString()` on `LogLines` to handle blank lines in log files
- **Script Execution**: Removed `begin`/`process`/`end` blocks from CLI script (pipeline blocks don't execute when running `.ps1` files directly)

### Removed
- Duplicated parsing logic between CLI and GUI scripts (now centralized in core module)

## [2.0.0] - 2025-10-20

### Added
- **Unified Tool**: Combined quick and detailed analysis into single script
- **Two Analysis Modes**: Quick mode for daily monitoring, Detailed mode for investigation
- **Smart AP Reboot Detection**: Advanced `remotewtptime` analysis with false positive filtering
- **RF Issue Analysis**: Detection of excessive frame acknowledgment failures
- **Infrastructure Event Detection**: Controller, CAPWAP, and hardware issue identification
- **Color-coded Output**: Severity-based color coding for easy issue identification
- **Flexible Parameters**: Device filtering, custom reports, and configurable event limits
- **Progress Tracking**: Visual feedback during log processing
- **Automated Reporting**: Detailed reports with recommendations in Detailed mode

### Changed
- **Improved Performance**: Optimized for processing 30K+ log lines in under 2 minutes
- **Enhanced Accuracy**: Better reboot detection excluding authentication events
- **Cleaner Output**: Organized results with clear categorization and recommendations

## [1.0.0] - 2025-10-20

### Added
- Initial release with separate Quick and Detailed analysis scripts
- Basic AP reboot detection using uptime analysis
- Frame failure detection for RF issues
- Infrastructure event pattern matching
- Console output with basic recommendations

---

## Version Numbering

- **Major version** (X.0.0): Breaking changes or major feature additions
- **Minor version** (0.X.0): New features, backwards compatible
- **Patch version** (0.0.X): Bug fixes, minor improvements

## Upgrade Notes

### From 2.x to 3.1
- No breaking changes - all existing parameters work the same
- New optional parameters: `-StartTime`, `-EndTime`, `-LogLevel`, `-RebootThreshold`, `-HighRFThreshold`, `-OutputFormat`, `-Quiet`
- GUI now requires `src/FortiAnalyzer.Core.psm1` in the `src/` subdirectory
- Reports now auto-generate as HTML (was Text in 2.x)

### From 1.x to 2.0
- Replace separate scripts with unified `FortiAnalyzer-AP-Analyzer.ps1`
- Update command line usage to include `-Mode` parameter
