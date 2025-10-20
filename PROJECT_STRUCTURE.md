# Project Structure

```
fortianalyzer-ap-analyzer/
├── 📄 FortiAnalyzer-AP-Analyzer.ps1    # Main analysis script (unified tool)
├── 📖 README.md                         # Main project documentation
├── 📋 CHANGELOG.md                      # Version history and changes
├── 🤝 CONTRIBUTING.md                   # Contribution guidelines
├── 📄 LICENSE                           # MIT License
├── 🚫 .gitignore                        # Git ignore patterns
├── 📁 .github/                          # GitHub templates and workflows
│   └── 📁 ISSUE_TEMPLATE/
│       ├── 🐛 bug_report.md             # Bug report template
│       └── ✨ feature_request.md        # Feature request template
├── 📁 examples/                         # Sample files and documentation
│   └── 📄 sample-log-entries.txt        # Sample FortiAnalyzer log entries
├── 📖 AP-Analyzer-Usage-Guide.md        # Detailed usage guide
├── 📋 Quick-Reference.md                # Quick parameter reference
└── 📄 PROJECT_STRUCTURE.md             # This file

## File Descriptions

### Core Files
- **FortiAnalyzer-AP-Analyzer.ps1**: The main PowerShell script that performs all analysis
- **README.md**: Primary documentation with installation, usage, and examples
- **LICENSE**: MIT license for open source distribution

### Documentation
- **AP-Analyzer-Usage-Guide.md**: Comprehensive usage guide with advanced examples
- **Quick-Reference.md**: Quick parameter reference and common use cases
- **CHANGELOG.md**: Version history and upgrade notes
- **CONTRIBUTING.md**: Guidelines for contributors

### Development
- **PROJECT_STRUCTURE.md**: This file explaining the project layout
- **.gitignore**: Excludes log files, reports, and temporary files from git
- **.github/**: GitHub-specific templates and automation

### Examples
- **examples/sample-log-entries.txt**: Sample FortiAnalyzer log entries for testing

## Key Features by File

### FortiAnalyzer-AP-Analyzer.ps1
- ✅ Unified Quick and Detailed analysis modes
- 🔍 Smart AP reboot detection using remotewtptime analysis
- 📡 RF issue identification (frame failures)
- 🏗️ Infrastructure event detection
- 🎨 Color-coded output with severity levels
- 📊 Automated report generation
- ⚡ Performance optimized for large files

### Documentation Coverage
- 🚀 Quick start examples
- 📖 Comprehensive parameter documentation
- 🎯 Use case scenarios
- 🔧 Troubleshooting guides
- 🤝 Contribution guidelines
- 📋 Issue templates

## Usage Workflow

1. **Quick Daily Check**: Use default Quick mode for monitoring
2. **Incident Investigation**: Use Detailed mode for root cause analysis
3. **Device-Specific Analysis**: Filter by device name for focused troubleshooting
4. **Batch Processing**: Analyze multiple log files automatically
5. **Report Generation**: Create detailed reports for documentation

## Maintenance

### Regular Updates
- Update CHANGELOG.md for new versions
- Keep README.md examples current
- Review and update documentation
- Test with new FortiAnalyzer versions

### Quality Assurance
- Test with various log formats
- Verify cross-platform compatibility
- Performance testing with large files
- Documentation accuracy checks