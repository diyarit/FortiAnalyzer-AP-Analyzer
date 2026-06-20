#Requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for FortiAnalyzer.Core module (v3.4 compatible).
.DESCRIPTION
    Tests log parsing, event detection, reboot heuristics, frame failures,
    recommendation engine, and report export.
.NOTES
    Run with: Invoke-Pester -Script ./tests/FortiAnalyzer.Core.Tests.ps1
#>

$modulePath = Join-Path (Join-Path $PSScriptRoot '..') 'src\FortiAnalyzer.Core.psm1'
Import-Module $modulePath -Force

Describe 'ConvertFrom-FortiLogLine' {
    It 'should parse a standard FortiAnalyzer log line' {
        $line = 'date=2025-10-20 time=04:52:19 devname="FW-01" ap="AP-01" remotewtptime="0.0" action="DNS-no-domain" msg="DNS lookup failed" logid=0100043573'
        $result = ConvertFrom-FortiLogLine -LogLine $line
        $result.date | Should Be '2025-10-20'
        $result.time | Should Be '04:52:19'
        $result.devname | Should Be 'FW-01'
        $result.ap | Should Be 'AP-01'
        $result.remotewtptime | Should Be '0.0'
        $result.action | Should Be 'DNS-no-domain'
    }

    It 'should parse quoted and unquoted values' {
        $line = 'date=2025-10-20 time=12:00:00 devname="FW-01" level=notice logid=0100032009'
        $result = ConvertFrom-FortiLogLine -LogLine $line
        $result.devname | Should Be 'FW-01'
        $result.level | Should Be 'notice'
    }

    It 'should handle line with no key-value pairs' {
        $result = ConvertFrom-FortiLogLine -LogLine 'this is just random text'
        $result.Count | Should Be 0
    }

    It 'should extract all fields from a complex log line' {
        $line = 'date=2025-10-20 time=05:15:12 devname="FW-01" ap="AP-01" stamac="aa:bb:cc:dd:ee:ff" signal=-59 snr=36 channel=60 remotewtptime="1375.295283" logid=0100043581 action="client-disconnected-by-wtp" msg="Client disconnected" level=notice subtype=wireless'
        $result = ConvertFrom-FortiLogLine -LogLine $line
        $result.stamac | Should Be 'aa:bb:cc:dd:ee:ff'
        $result.signal | Should Be '-59'
        $result.snr | Should Be '36'
        $result.channel | Should Be '60'
        $result.subtype | Should Be 'wireless'
    }
}

Describe 'Get-FortiLogMessageID' {
    It 'should extract last 5 digits from a 10-digit logid' {
        Get-FortiLogMessageID -LogID '0100043555' | Should Be '43555'
    }

    It 'should return null for short logid' {
        Get-FortiLogMessageID -LogID '123' | Should BeNullOrEmpty
    }

    It 'should handle exactly 5 digits' {
        Get-FortiLogMessageID -LogID '43555' | Should Be '43555'
    }
}

Describe 'Get-EventDefinition' {
    It 'should return definition for known AP Reboot logid' {
        $def = Get-EventDefinition -LogID '0100043555'
        $def | Should Not BeNullOrEmpty
        $def.Cat | Should Be 'Wireless'
        $def.Sev | Should Be 'Critical'
        $def.Desc | Should Be 'AP Rebooted (WTP Reset)'
    }

    It 'should return definition for HA failover' {
        $def = Get-EventDefinition -LogID '0100035016'
        $def.Cat | Should Be 'System'
        $def.Sev | Should Be 'Notice'
    }

    It 'should return definition for VPN tunnel down' {
        $def = Get-EventDefinition -LogID '0100033002'
        $def.Cat | Should Be 'VPN'
        $def.Sev | Should Be 'Warning'
    }

    It 'should return null for unknown logid' {
        Get-EventDefinition -LogID '0100099999' | Should BeNullOrEmpty
    }

    It 'should have critical severity for system crash' {
        $def = Get-EventDefinition -LogID '0100032003'
        $def.Sev | Should Be 'Critical'
    }
}

Describe 'Get-FortiAnalysisResults' {
    $sampleLines = @(
        'date=2025-10-20 time=04:52:19 devname="FW-01" ap="AP-01" remotewtptime="0.0" logid=0100043573 subtype=wireless action="client-authentication" level=notice msg="Client authenticated"',
        'date=2025-10-20 time=04:52:27 devname="FW-01" ap="AP-01" remotewtptime="9.741713" logid=0100043673 subtype=wireless action="DNS-no-domain" level=warning msg="DNS lookup failed"',
        'date=2025-10-20 time=05:15:12 devname="FW-01" ap="AP-01" stamac="aa:bb:cc:dd:ee:ff" logid=0100043581 subtype=wireless action="client-disconnected-by-wtp" level=notice msg="Client disconnected by WTP." reason="excessive number of frames"',
        'date=2025-10-18 time=21:18:26 devname="FW-01" ap="AP-01" logid=0100043590 subtype=wireless action="power-change" level=info msg="AP power level changed"',
        'date=2025-10-18 time=21:18:16 devname="FW-01" ap="AP-01" logid=0100043591 subtype=wireless action="radar-detected" level=warning msg="Radar detected, channel change"',
        'date=2025-10-20 time=03:15:22 devname="FG-01" logid=0100035016 subtype=ha level=notice msg="HA failover occurred"',
        'date=2025-10-20 time=10:00:00 devname="SW-01" switchid="SW-01" logid=0100032605 subtype=switch-controller level=info msg="Switch joined"',
        'date=2025-10-20 time=11:00:00 devname="FG-01" logid=0100022931 subtype=sdwan level=warning msg="SD-WAN SLA failed"'
    )

    It 'should detect AP reboot via remotewtptime=0.0' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines
        $reboots = $results.WirelessEvents | Where-Object { $_.Desc -match 'Reboot' }
        $reboots | Should Not BeNullOrEmpty
    }

    It 'should detect heuristic reboot via low remotewtptime' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines -RebootThreshold 30
        $heuristic = $results.WirelessEvents | Where-Object { $_.Desc -eq 'AP Reboot (Heuristic)' }
        $heuristic | Should Not BeNullOrEmpty
    }

    It 'should not treat high remotewtptime as reboot' {
        $line = 'date=2025-10-20 time=12:00:00 devname="FW-01" ap="AP-01" remotewtptime="86400.0" logid=0100043573 subtype=wireless level=notice msg="Normal auth"'
        $results = Get-FortiAnalysisResults -LogLines @($line)
        $reboots = $results.WirelessEvents | Where-Object { $_.Desc -match 'Reboot' }
        $reboots.Count | Should Be 0
    }

    It 'should detect frame failures' {
        $line = 'date=2025-10-20 time=05:15:12 devname="FW-01" ap="AP-01" stamac="aa:bb:cc:dd:ee:ff" logid=0100043581 subtype=wireless action="client-disconnected-by-wtp" level=notice msg="Client disconnected by WTP due to excessive frames"'
        $results = Get-FortiAnalysisResults -LogLines @($line)
        $results.FrameFailures.Count | Should Be 1
        $results.FrameFailures[0].ClientMAC | Should Be 'aa:bb:cc:dd:ee:ff'
    }

    It 'should filter by device name' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines -DeviceFilter 'FW-01'
        $allEvents = @() + $results.SystemEvents + $results.WirelessEvents + $results.SwitchEvents + $results.SDWANEvents
        $allDevices = $allEvents | Select-Object -ExpandProperty Device -Unique
        $allDevices.Count | Should Be 1
        $allDevices | Should Be 'FW-01'
    }

    It 'should detect HA events' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines
        $haEvents = $results.SystemEvents | Where-Object { $_.Desc -match 'HA' }
        $haEvents | Should Not BeNullOrEmpty
    }

    It 'should detect switch events' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines
        $results.SwitchEvents | Should Not BeNullOrEmpty
    }

    It 'should detect SD-WAN events' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines
        $results.SDWANEvents | Should Not BeNullOrEmpty
    }

    It 'should populate summary correctly' {
        $results = Get-FortiAnalysisResults -LogLines $sampleLines -DeviceFilter 'FW-01'
        $results.Summary.TotalLines | Should Be 8
        $results.Summary.DeviceFilter | Should Be 'FW-01'
    }

    It 'should handle empty log lines' {
        $results = Get-FortiAnalysisResults -LogLines @()
        $results.SystemEvents.Count | Should Be 0
        $results.WirelessEvents.Count | Should Be 0
        $results.Summary.TotalLines | Should Be 0
    }
}

Describe 'New-FortiRecommendation' {
    It 'should generate OK when no issues found' {
        $results = @{
            SystemEvents = @()
            SwitchEvents = @()
            WirelessEvents = @()
            SDWANEvents = @()
            HardwareEvents = @()
            VPNEvents = @()
            RouterEvents = @()
            UserEvents = @()
            FrameFailures = @()
        }
        $recs = New-FortiRecommendation -Results $results
        $okRec = $recs | Where-Object { $_.Level -eq 'OK' }
        $okRec | Should Not BeNullOrEmpty
    }

    It 'should generate Critical for AP reboots' {
        $results = @{
            SystemEvents = @()
            SwitchEvents = @()
            WirelessEvents = @([PSCustomObject]@{ Desc = 'AP Reboot (Heuristic)'; Severity = 'Critical' })
            SDWANEvents = @()
            HardwareEvents = @()
            VPNEvents = @()
            RouterEvents = @()
            UserEvents = @()
            FrameFailures = @()
        }
        $recs = New-FortiRecommendation -Results $results
        $critRecs = $recs | Where-Object { $_.Level -eq 'Critical' -and $_.Message -match 'REBOOT' }
        $critRecs | Should Not BeNullOrEmpty
    }

    It 'should generate Warning for high frame failures' {
        $failures = 1..25 | ForEach-Object {
            [PSCustomObject]@{ Desc = 'Excessive Frame Failures'; Severity = 'Warning' }
        }
        $results = @{
            SystemEvents = @()
            SwitchEvents = @()
            WirelessEvents = @()
            SDWANEvents = @()
            HardwareEvents = @()
            VPNEvents = @()
            RouterEvents = @()
            UserEvents = @()
            FrameFailures = $failures
        }
        $recs = New-FortiRecommendation -Results $results -HighRFThreshold 20
        $rfRec = $recs | Where-Object { $_.Message -match 'RF QUALITY' }
        $rfRec | Should Not BeNullOrEmpty
    }

    It 'should generate Critical for hardware alarms' {
        $results = @{
            SystemEvents = @()
            SwitchEvents = @()
            WirelessEvents = @()
            SDWANEvents = @()
            HardwareEvents = @([PSCustomObject]@{ Desc = 'Fan Failure/Anomaly'; Severity = 'Critical' })
            VPNEvents = @()
            RouterEvents = @()
            UserEvents = @()
            FrameFailures = @()
        }
        $recs = New-FortiRecommendation -Results $results
        $hwRec = $recs | Where-Object { $_.Level -eq 'Critical' -and $_.Message -match 'HARDWARE' }
        $hwRec | Should Not BeNullOrEmpty
    }

    It 'should generate Critical for HA events' {
        $results = @{
            SystemEvents = @([PSCustomObject]@{ Desc = 'HA Heartbeat Lost'; Severity = 'Critical' })
            SwitchEvents = @()
            WirelessEvents = @()
            SDWANEvents = @()
            HardwareEvents = @()
            VPNEvents = @()
            RouterEvents = @()
            UserEvents = @()
            FrameFailures = @()
        }
        $recs = New-FortiRecommendation -Results $results
        $haRec = $recs | Where-Object { $_.Level -eq 'Critical' -and $_.Message -match 'HA' }
        $haRec | Should Not BeNullOrEmpty
    }
}

Describe 'Export-FortiReport' {
    $testResults = @{
        SystemEvents = @([PSCustomObject]@{ DateTime = '2025-10-20 10:00:00'; Device = 'FW-01'; Source = 'N/A'; Message = 'Test'; Desc = 'Test Event'; Severity = 'Info'; Category = 'System'; LogID = '0100032009' })
        SwitchEvents = @()
        WirelessEvents = @()
        SDWANEvents = @()
        HardwareEvents = @()
        VPNEvents = @()
        RouterEvents = @()
        UserEvents = @()
        FrameFailures = @()
        Summary = @{ TotalLines = 100; ProcessedAt = Get-Date; DeviceFilter = $null; TimeRange = 'All' }
    }
    $testRecs = @([PSCustomObject]@{ Level = 'OK'; Message = 'Test recommendation' })
    $outDir = Join-Path $TestDrive 'exports'
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null

    It 'should export JSON report' {
        $path = Join-Path $outDir 'test.json'
        Export-FortiReport -Results $testResults -Recommendations $testRecs -OutputPath $path -Format 'JSON'
        Test-Path $path | Should Be $true
        $content = Get-Content $path -Raw | ConvertFrom-Json
        $content.Summary.TotalLines | Should Be 100
    }

    It 'should export CSV report' {
        $path = Join-Path $outDir 'test.csv'
        Export-FortiReport -Results $testResults -Recommendations $testRecs -OutputPath $path -Format 'CSV'
        Test-Path $path | Should Be $true
        $csv = Get-Content $path
        $csv.Count | Should Be 2
    }

    It 'should export HTML report' {
        $path = Join-Path $outDir 'test.html'
        Export-FortiReport -Results $testResults -Recommendations $testRecs -OutputPath $path -Format 'HTML'
        Test-Path $path | Should Be $true
        $content = Get-Content $path -Raw
        $content | Should Match 'FortiAnalyzer'
        $content | Should Match 'Test Event'
    }

    It 'should export Text report' {
        $path = Join-Path $outDir 'test.txt'
        Export-FortiReport -Results $testResults -Recommendations $testRecs -OutputPath $path -Format 'Text'
        Test-Path $path | Should Be $true
        $content = Get-Content $path -Raw
        $content | Should Match 'System/HA Events'
    }
}
