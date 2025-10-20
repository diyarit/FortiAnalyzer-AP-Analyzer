# Changelog

All notable changes to the FortiAnalyzer AP Analyzer project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Technical Details
- **PowerShell 5.1+** compatibility
- **Cross-platform** support (Windows, Linux, macOS with PowerShell Core)
- **Memory efficient** processing for large log files
- **Regex-based** log parsing for reliability

## [1.0.0] - 2025-10-20

### Added
- Initial release with separate Quick and Detailed analysis scripts
- Basic AP reboot detection using uptime analysis
- Frame failure detection for RF issues
- Infrastructure event pattern matching
- Console output with basic recommendations

### Features
- FortiAnalyzer wireless log parsing
- AP offline event detection
- Basic reporting capabilities
- PowerShell 5.1+ support

---

## Version Numbering

- **Major version** (X.0.0): Breaking changes or major feature additions
- **Minor version** (0.X.0): New features, backwards compatible
- **Patch version** (0.0.X): Bug fixes, minor improvements

## Upgrade Notes

### From 1.x to 2.0
- Replace separate scripts with unified `FortiAnalyzer-AP-Analyzer.ps1`
- Update command line usage to include `-Mode` parameter
- Review new parameter options for enhanced functionality