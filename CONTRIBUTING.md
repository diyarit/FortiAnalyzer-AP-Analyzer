# Contributing to FortiAnalyzer AP Analyzer

Thank you for your interest in contributing to the FortiAnalyzer AP Analyzer! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
1. **Search existing issues** first to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Include sample log entries** (sanitized of sensitive data)
4. **Specify your environment**: PowerShell version, OS, log format

### Suggesting Features
1. **Check existing feature requests** in issues
2. **Describe the use case** and business value
3. **Provide examples** of how it would work
4. **Consider backwards compatibility**

### Code Contributions

#### Getting Started
1. **Fork** the repository
2. **Clone** your fork locally
3. **Create a branch** for your feature/fix
4. **Make your changes**
5. **Test thoroughly**
6. **Submit a pull request**

```bash
git clone https://github.com/yourusername/fortianalyzer-ap-analyzer.git
cd fortianalyzer-ap-analyzer
git checkout -b feature/your-feature-name
```

#### Development Guidelines

##### PowerShell Best Practices
- Use **approved verbs** for function names (`Get-`, `Set-`, `Test-`, etc.)
- Follow **PascalCase** for functions and variables
- Use **meaningful parameter names** with proper types
- Include **parameter validation** where appropriate
- Add **comment-based help** for functions

##### Code Style
```powershell
# Good: Clear parameter definition
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$LogPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Quick", "Detailed")]
    [string]$Mode = "Quick"
)

# Good: Descriptive function names
function Get-APRebootEvents {
    param([array]$LogLines)
    # Implementation
}

# Good: Clear variable names
$rebootEvents = @()
$frameFailureCount = 0
```

##### Error Handling
- Use **try/catch blocks** for operations that might fail
- Provide **meaningful error messages**
- **Continue processing** when possible, don't fail completely

```powershell
try {
    $logContent = Get-Content -Path $LogPath -ErrorAction Stop
} catch {
    Write-Error "Failed to read log file: $($_.Exception.Message)"
    return
}
```

##### Performance Considerations
- **Process large files efficiently** (avoid loading everything into memory)
- **Use appropriate data structures** (arrays vs hashtables)
- **Minimize regex operations** in tight loops
- **Provide progress feedback** for long operations

#### Testing Your Changes

##### Manual Testing
1. **Test with various log formats** and sizes
2. **Verify both Quick and Detailed modes**
3. **Test error conditions** (missing files, invalid formats)
4. **Check performance** with large files (30K+ lines)

##### Test Cases to Cover
- Empty log files
- Malformed log entries
- Very large files (>100MB)
- Files with no AP events
- Files with many AP reboots
- Different FortiAnalyzer versions/formats

##### Sample Test Commands
```powershell
# Test basic functionality
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "test-small.log"

# Test detailed mode
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "test-large.log" -Mode Detailed

# Test device filtering
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "test.log" -DeviceName "TEST-AP"

# Test error handling
.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "nonexistent.log"
```

## 📋 Pull Request Process

### Before Submitting
- [ ] **Code follows** PowerShell best practices
- [ ] **All parameters** have proper validation
- [ ] **Error handling** is implemented
- [ ] **Comments** explain complex logic
- [ ] **Testing** completed on multiple log formats
- [ ] **Documentation** updated if needed

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested with small log files
- [ ] Tested with large log files (>30K lines)
- [ ] Tested error conditions
- [ ] Tested both Quick and Detailed modes

## Checklist
- [ ] Code follows PowerShell best practices
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

### Review Process
1. **Automated checks** will run on your PR
2. **Maintainer review** for code quality and functionality
3. **Testing** with various log formats
4. **Merge** after approval

## 🐛 Bug Reports

### Information to Include
- **PowerShell version**: `$PSVersionTable.PSVersion`
- **Operating system**: Windows/Linux/macOS version
- **Log file details**: Size, FortiAnalyzer version, format
- **Command used**: Exact command line that failed
- **Error message**: Full error output
- **Expected behavior**: What should have happened
- **Sample log entries**: Sanitized examples (remove sensitive data)

### Sample Bug Report
```markdown
**PowerShell Version**: 5.1.19041.1682
**OS**: Windows 10 Pro 21H2
**Log File**: 50MB, FortiAnalyzer 7.0.1
**Command**: `.\FortiAnalyzer-AP-Analyzer.ps1 -LogPath "large.log" -Mode Detailed`

**Error**:
```
[ERROR] Error during analysis: Index was outside the bounds of the array.
```

**Expected**: Should process the log and show results
**Sample Log Entry**: 
```
date=2025-10-20 time=06:31:16 devname="AP-01" ap="AP-01" msg="test"
```
```

## 🎯 Feature Requests

### Good Feature Requests Include
- **Clear use case**: Why is this needed?
- **Detailed description**: How should it work?
- **Examples**: Sample input/output
- **Backwards compatibility**: Impact on existing functionality

### Feature Ideas We're Interested In
- **Additional log formats** (other vendors, different FortiAnalyzer versions)
- **Export formats** (JSON, XML, database integration)
- **Advanced filtering** (time ranges, event types)
- **Alerting integration** (email, webhooks, SIEM)
- **Performance improvements** for very large files
- **GUI interface** for non-PowerShell users

## 📚 Documentation

### Documentation Standards
- **Clear examples** with expected output
- **Parameter descriptions** with valid values
- **Use cases** for different scenarios
- **Troubleshooting** common issues

### Areas Needing Documentation
- Additional usage examples
- Integration with monitoring systems
- Performance tuning guidelines
- Log format specifications

## 🏷️ Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

## 📞 Getting Help

- **Questions**: Create an issue with the "question" label
- **Discussions**: Use GitHub Discussions for general topics
- **Real-time help**: Check if there's a community chat/Slack

## 🙏 Recognition

Contributors will be:
- **Listed** in the README.md contributors section
- **Credited** in release notes for significant contributions
- **Thanked** in the project documentation

Thank you for helping make FortiAnalyzer AP Analyzer better for everyone!