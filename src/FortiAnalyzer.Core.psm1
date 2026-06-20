#Requires -Version 5.1
<#
.SYNOPSIS
    FortiAnalyzer Core Module - Shared parsing, event detection, and analysis logic.
.DESCRIPTION
    Provides unified log parsing, event definitions, analysis functions, and reporting
    used by both the CLI and GUI versions of the FortiAnalyzer AP Analyzer.
.NOTES
    Version: 3.1.0
    Author:  FortiAnalyzer AP Analyzer Project
#>

# ============================================================================
# COMPILED REGEX (created once, reused for performance)
# ============================================================================
$script:RegexPatterns = @{
    KeyValue    = [regex]::new('([a-zA-Z0-9_]+)=(?:"([^"]*)"|([^"\s]+))', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    LogID       = [regex]::new('logid=(\d{10})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    LowUptime   = [regex]::new('remotewtptime="([0-9]+\.?[0-9]*)"', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    FrameFail   = [regex]::new('client-disconnected-by-wtp.*excessive.*frames', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    DateTime    = [regex]::new('date=(\d{4}-\d{2}-\d{2})\s+time=(\d{2}:\d{2}:\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    HasLogID    = [regex]::new('logid=', [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

# ============================================================================
# COMPLETE EVENT DEFINITIONS (100+ log IDs)
# ============================================================================
$script:EventCatalog = @{
    # ── System Events (subtype=system) ──────────────────────────────────────
    '0100032009' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'System Started (Reboot/Power-on)' }
    '0100032200' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'System Shutdown (Controlled)' }
    '0100032003' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'System Reset by Watchdog (Crash)' }
    '0100022011' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'Entered Conserve Mode (Mem/CPU)' }
    '0100022012' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'Exited Conserve Mode' }
    '0100032000' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'System Config Changed' }
    '0100032001' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'System Config Restored' }
    '0100032002' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'System Config Backup' }
    '0100032004' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'System Time Changed' }
    '0100032005' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'Admin Login' }
    '0100032006' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'Admin Logout' }
    '0100032007' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'Admin Login Failed' }
    '0100032008' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'FortiGuard License Update' }
    '0100032010' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'System Disk Space Low' }
    '0100032011' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'Interface Link Down' }
    '0100032012' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'Interface Link Up' }
    '0100032013' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'NTP Sync Success' }
    '0100032014' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'NTP Sync Failure' }
    '0100032201' = @{ Cat = 'System';  Sev = 'Notice';   Desc = 'System Reboot Request' }
    '0100032300' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'Certificate Expiry Warning' }
    '0100032400' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'License Expired' }
    '0100032401' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'License Expiring Soon' }
    '0100044548' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'CLI Command Executed' }

    # ── HA Events (subtype=ha) ──────────────────────────────────────────────
    '0100035001' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Unit Becomes Primary' }
    '0100035002' = @{ Cat = 'System';  Sev = 'Notice';   Desc = 'HA Unit Becomes Secondary' }
    '0100035003' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'HA Heartbeat Lost' }
    '0100035004' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Heartbeat Restored' }
    '0100035005' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Config Sync Started' }
    '0100035006' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Config Sync Completed' }
    '0100035007' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'HA Monitor Interface Down' }
    '0100035008' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Monitor Interface Up' }
    '0100035009' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'HA Ping Server Check Failed' }
    '0100035010' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Session Sync Started' }
    '0100035011' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'HA Sync Failed' }
    '0100035012' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Session Sync Completed' }
    '0100035013' = @{ Cat = 'System';  Sev = 'Critical'; Desc = 'HA Failover Failed' }
    '0100035014' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Override Enabled/Disabled' }
    '0100035015' = @{ Cat = 'System';  Sev = 'Notice';   Desc = 'HA Priority Changed' }
    '0100035016' = @{ Cat = 'System';  Sev = 'Notice';   Desc = 'HA Failover Success' }
    '0100035017' = @{ Cat = 'System';  Sev = 'Info';     Desc = 'HA Cluster Member Added' }
    '0100035018' = @{ Cat = 'System';  Sev = 'Warning';  Desc = 'HA Cluster Member Removed' }

    # ── Hardware Events ─────────────────────────────────────────────────────
    '0100022108' = @{ Cat = 'Hardware'; Sev = 'Critical'; Desc = 'Fan Failure/Anomaly' }
    '0100022109' = @{ Cat = 'Hardware'; Sev = 'Critical'; Desc = 'Temperature High (Overheat)' }

    # ── Wireless Events (subtype=wireless) ──────────────────────────────────
    '0100043501' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Discovery' }
    '0100043502' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Configuration Changed' }
    '0100043503' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Image Download Started' }
    '0100043504' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Image Download Complete' }
    '0100043505' = @{ Cat = 'Wireless'; Sev = 'Critical'; Desc = 'AP Image Download Failed' }
    '0100043506' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Firmware Upgrade Started' }
    '0100043507' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Firmware Upgrade Complete' }
    '0100043508' = @{ Cat = 'Wireless'; Sev = 'Critical'; Desc = 'AP Firmware Upgrade Failed' }
    '0100043509' = @{ Cat = 'Wireless'; Sev = 'Critical'; Desc = 'AP Rogue Detected' }
    '0100043510' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'AP Rogue Contained' }
    '0100043511' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Rogue Removed' }
    '0100043512' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Authenticated' }
    '0100043513' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Deauthenticated' }
    '0100043514' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Disassociated' }
    '0100043515' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Connected (802.11)' }
    '0100043516' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Disconnected (802.11)' }
    '0100043517' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Client Roaming' }
    '0100043520' = @{ Cat = 'Wireless'; Sev = 'Notice';   Desc = 'Radio Channel Changed' }
    '0100043521' = @{ Cat = 'Wireless'; Sev = 'Notice';   Desc = 'Radio Power Changed' }
    '0100043522' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Radio Enabled' }
    '0100043523' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Radio Disabled' }
    '0100043524' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'DFS Channel Available' }
    '0100043525' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'DFS Channel Unavailable' }
    '0100043527' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'CAPWAP Tunnel Down' }
    '0100043530' = @{ Cat = 'Wireless'; Sev = 'Notice';   Desc = 'AP Station Count Changed' }
    '0100043540' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Client Disconnected by WTP (Excessive Frames)' }
    '0100043545' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Radio Background Scan Started' }
    '0100043546' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'Radio Background Scan Completed' }
    '0100043547' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Interference Detected' }
    '0100043548' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Radio Interference' }
    '0100043549' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Client Authentication Failed' }
    '0100043550' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Client Authentication Timeout' }
    '0100043551' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Joined Controller' }
    '0100043552' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'AP Left Controller (Offline)' }
    '0100043553' = @{ Cat = 'Wireless'; Sev = 'Info';     Desc = 'AP Config Sync Complete' }
    '0100043554' = @{ Cat = 'Wireless'; Sev = 'Critical'; Desc = 'AP Config Sync Failed' }
    '0100043555' = @{ Cat = 'Wireless'; Sev = 'Critical'; Desc = 'AP Rebooted (WTP Reset)' }
    '0100043556' = @{ Cat = 'Wireless'; Sev = 'Warning';  Desc = 'Radar Detected (DFS)' }

    # ── Switch Controller Events (subtype=switch-controller) ────────────────
    '0100032601' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch Discovered' }
    '0100032602' = @{ Cat = 'Switch'; Sev = 'Notice';   Desc = 'Switch Authorization Changed' }
    '0100032603' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch Configuration Changed' }
    '0100032604' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch Firmware Upgrade' }
    '0100032605' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch Online (Joined)' }
    '0100032606' = @{ Cat = 'Switch'; Sev = 'Critical'; Desc = 'Switch Offline (Tunnel Down)' }
    '0100032607' = @{ Cat = 'Switch'; Sev = 'Notice';   Desc = 'Switch VLAN Changed' }
    '0100032608' = @{ Cat = 'Switch'; Sev = 'Critical'; Desc = 'Switch Port Security Violation' }
    '0100032609' = @{ Cat = 'Switch'; Sev = 'Warning';  Desc = 'Switch MAC Address Table Full' }
    '0100032610' = @{ Cat = 'Switch'; Sev = 'Warning';  Desc = 'Switch Spanning Tree Blocked Port' }
    '0100032620' = @{ Cat = 'Switch'; Sev = 'Critical'; Desc = 'Switch PoE Budget Exceeded' }
    '0100032621' = @{ Cat = 'Switch'; Sev = 'Warning';  Desc = 'Switch PoE Power Budget Low' }
    '0100032622' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch PoE Port Power On' }
    '0100032623' = @{ Cat = 'Switch'; Sev = 'Notice';   Desc = 'Switch PoE Port Power Off' }
    '0100032630' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch LLDP Neighbor Discovered' }
    '0100032631' = @{ Cat = 'Switch'; Sev = 'Notice';   Desc = 'Switch LLDP Neighbor Lost' }
    '0100032640' = @{ Cat = 'Switch'; Sev = 'Critical'; Desc = 'Switch Port Error Disabled' }
    '0100032650' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch NAC Policy Applied' }
    '0100032694' = @{ Cat = 'Switch'; Sev = 'Warning';  Desc = 'Switch PoE Error' }
    '0100032695' = @{ Cat = 'Switch'; Sev = 'Info';     Desc = 'Switch Port Link Status' }
    '0100032696' = @{ Cat = 'Switch'; Sev = 'Warning';  Desc = 'STP Topology Change' }

    # ── SD-WAN Events (subtype=sdwan) ──────────────────────────────────────
    '0100022923' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'Virtual WAN Link Status' }
    '0100022924' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'Virtual WAN Link Volume Status' }
    '0100022925' = @{ Cat = 'SDWAN'; Sev = 'Information'; Desc = 'Virtual WAN Link SLA Information' }
    '0100022926' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'Virtual WAN Link Neighbor Status' }
    '0100022927' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'Virtual WAN Link Neighbor Standalone' }
    '0100022928' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'Virtual WAN Link Neighbor Primary' }
    '0100022929' = @{ Cat = 'SDWAN'; Sev = 'Warning';     Desc = 'Virtual WAN Link Neighbor Secondary' }
    '0100022930' = @{ Cat = 'SDWAN'; Sev = 'Warning';     Desc = 'SD-WAN Health Check Failed' }
    '0100022931' = @{ Cat = 'SDWAN'; Sev = 'Warning';     Desc = 'SD-WAN SLA Failed (Packet Loss/Latency)' }
    '0100022932' = @{ Cat = 'SDWAN'; Sev = 'Critical';    Desc = 'SD-WAN Member Down' }
    '0100022933' = @{ Cat = 'SDWAN'; Sev = 'Info';        Desc = 'SD-WAN Member Up' }
    '0100022934' = @{ Cat = 'SDWAN'; Sev = 'Info';        Desc = 'SD-WAN Service Rule Match' }
    '0100022935' = @{ Cat = 'SDWAN'; Sev = 'Notice';      Desc = 'SD-WAN Quality of Service Changed' }

    # ── VPN Events (subtype=vpn) ───────────────────────────────────────────
    '0100033001' = @{ Cat = 'VPN'; Sev = 'Info';     Desc = 'IPsec Tunnel Up' }
    '0100033002' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'IPsec Tunnel Down' }
    '0100033003' = @{ Cat = 'VPN'; Sev = 'Info';     Desc = 'SSL VPN Login Success' }
    '0100033004' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'SSL VPN Login Failed' }
    '0100033005' = @{ Cat = 'VPN'; Sev = 'Info';     Desc = 'SSL VPN Tunnel Up' }
    '0100033006' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'SSL VPN Tunnel Down' }
    '0100033007' = @{ Cat = 'VPN'; Sev = 'Info';     Desc = 'IPsec Phase 1 Established' }
    '0100033008' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'IPsec Phase 1 Failed' }
    '0100033009' = @{ Cat = 'VPN'; Sev = 'Info';     Desc = 'IPsec Phase 2 Established' }
    '0100033010' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'IPsec Phase 2 Failed' }
    '0100033012' = @{ Cat = 'VPN'; Sev = 'Warning';  Desc = 'VPN Tunnel Authentication Failed' }

    # ── Router Events (subtype=router) ─────────────────────────────────────
    '0100030101' = @{ Cat = 'Router'; Sev = 'Info';     Desc = 'BGP Neighbor Up' }
    '0100030102' = @{ Cat = 'Router'; Sev = 'Warning';  Desc = 'BGP Neighbor Down' }
    '0100030103' = @{ Cat = 'Router'; Sev = 'Info';     Desc = 'OSPF Neighbor Adjacency Up' }
    '0100030104' = @{ Cat = 'Router'; Sev = 'Warning';  Desc = 'OSPF Neighbor Adjacency Down' }
    '0100030105' = @{ Cat = 'Router'; Sev = 'Info';     Desc = 'Static Route Added' }
    '0100030106' = @{ Cat = 'Router'; Sev = 'Notice';   Desc = 'Static Route Removed' }
    '0100030107' = @{ Cat = 'Router'; Sev = 'Info';     Desc = 'DHCP Server Lease Assigned' }
    '0100030108' = @{ Cat = 'Router'; Sev = 'Notice';   Desc = 'DHCP Server Lease Expired' }
    '0100030110' = @{ Cat = 'Router'; Sev = 'Warning';  Desc = 'DNS Query Failed' }

    # ── User/Authentication Events (subtype=user) ──────────────────────────
    '0100034001' = @{ Cat = 'User'; Sev = 'Info';     Desc = 'User Login Success' }
    '0100034002' = @{ Cat = 'User'; Sev = 'Warning';  Desc = 'User Login Failed' }
    '0100034003' = @{ Cat = 'User'; Sev = 'Info';     Desc = 'User Logout' }
    '0100034004' = @{ Cat = 'User'; Sev = 'Info';     Desc = 'User Authenticated via RADIUS' }
    '0100034005' = @{ Cat = 'User'; Sev = 'Info';     Desc = 'User Authenticated via LDAP' }
    '0100034008' = @{ Cat = 'User'; Sev = 'Notice';   Desc = 'User Session Timeout' }
    '0100034009' = @{ Cat = 'User'; Sev = 'Warning';  Desc = 'User Locked Out' }
    '0100034010' = @{ Cat = 'User'; Sev = 'Warning';  Desc = 'User Password Expired' }
}

# ============================================================================
# LOG PARSING
# ============================================================================

function ConvertFrom-FortiLogLine {
    <#
    .SYNOPSIS
        Parses a single FortiAnalyzer log line into a hashtable of key-value pairs.
    .DESCRIPTION
        Uses a compiled regex for high-performance extraction of all key=value
        and key="value" fields from FortiAnalyzer log format.
    .PARAMETER LogLine
        A single raw log line string.
    .OUTPUTS
        Hashtable with extracted fields.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$LogLine
    )

    $logData = @{}
    $matches = $script:RegexPatterns.KeyValue.Matches($LogLine)
    foreach ($m in $matches) {
        $key = $m.Groups[1].Value
        $value = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { $m.Groups[3].Value }
        $logData[$key] = $value
    }
    return $logData
}

function Get-FortiLogMessageID {
    <#
    .SYNOPSIS
        Extracts the 5-digit message ID suffix from a FortiAnalyzer logid.
    .PARAMETER LogID
        The full 10-digit logid string (e.g., "0100043555").
    .OUTPUTS
        String - the last 5 digits (e.g., "43555").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogID
    )
    if ($LogID.Length -ge 5) {
        return $LogID.Substring($LogID.Length - 5)
    }
    return $null
}

function Get-EventDefinition {
    <#
    .SYNOPSIS
        Looks up an event definition by full 10-digit logid.
    .PARAMETER LogID
        Full logid string.
    .OUTPUTS
        Hashtable with Cat, Sev, Desc keys, or $null if not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogID
    )
    if ($script:EventCatalog.ContainsKey($LogID)) {
        return $script:EventCatalog[$LogID]
    }
    return $null
}

# ============================================================================
# ANALYSIS FUNCTIONS
# ============================================================================

function Get-FortiAnalysisResults {
    <#
    .SYNOPSIS
        Performs a unified analysis of FortiAnalyzer log lines.
    .DESCRIPTION
        Scans log lines for system, HA, wireless, switch, SD-WAN, VPN, router,
        and user events using the complete event catalog. Also detects AP reboots
        via heuristic (low remotewtptime) and excessive frame failures.
    .PARAMETER LogLines
        Array of log line strings.
    .PARAMETER DeviceFilter
        Optional device name to filter events.
    .PARAMETER StartTime
        Optional start time for time-range filtering.
    .PARAMETER EndTime
        Optional end time for time-range filtering.
    .PARAMETER LogLevel
        Optional minimum log level to include (emergency, alert, critical, error, warning, notice, information, debug).
    .PARAMETER RebootThreshold
        Maximum remotewtptime (seconds) to consider as a reboot. Default: 30.
    .OUTPUTS
        Hashtable with categorized event arrays.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$LogLines,

        [string]$DeviceFilter,

        [datetime]$StartTime,

        [datetime]$EndTime,

        [ValidateSet('emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'information', 'debug')]
        [string]$LogLevel,

        [double]$RebootThreshold = 30.0
    )

    $Results = @{
        SystemEvents    = [System.Collections.Generic.List[object]]::new()
        SwitchEvents    = [System.Collections.Generic.List[object]]::new()
        WirelessEvents  = [System.Collections.Generic.List[object]]::new()
        SDWANEvents     = [System.Collections.Generic.List[object]]::new()
        HardwareEvents  = [System.Collections.Generic.List[object]]::new()
        VPNEvents       = [System.Collections.Generic.List[object]]::new()
        RouterEvents    = [System.Collections.Generic.List[object]]::new()
        UserEvents      = [System.Collections.Generic.List[object]]::new()
        FrameFailures   = [System.Collections.Generic.List[object]]::new()
        Summary         = @{
            TotalLines    = $LogLines.Count
            ProcessedAt   = Get-Date
            DeviceFilter  = $DeviceFilter
            TimeRange     = if ($StartTime -and $EndTime) { "$StartTime to $EndTime" } else { "All" }
        }
    }

    # Severity hierarchy for level filtering
    $sevOrder = @{
        'emergency' = 0; 'alert' = 1; 'critical' = 2; 'error' = 3
        'warning' = 4; 'notice' = 5; 'information' = 6; 'debug' = 7
    }
    $minSevLevel = if ($LogLevel) { $sevOrder[$LogLevel] } else { 99 }

    # Dedup set for heuristic reboots
    $heuristicRebootKeys = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $LogLines) {
        # Pre-filter: skip lines without logid
        if (-not $script:RegexPatterns.HasLogID.IsMatch($line)) { continue }

        $data = ConvertFrom-FortiLogLine $line

        # Device filter
        if ($DeviceFilter -and $data.devname -and $data.devname -ne $DeviceFilter) { continue }

        # Time range filter
        if ($StartTime -or $EndTime) {
            if ($data.date -and $data.time) {
                try {
                    $eventTime = [datetime]::ParseExact("$($data.date) $($data.time)", "yyyy-MM-dd HH:mm:ss", $null)
                    if ($StartTime -and $eventTime -lt $StartTime) { continue }
                    if ($EndTime -and $eventTime -gt $EndTime) { continue }
                } catch { }
            }
        }

        # Level filter
        if ($LogLevel -and $data.level) {
            $lineSev = $sevOrder[$data.level.ToLower()]
            if ($null -ne $lineSev -and $lineSev -gt $minSevLevel) { continue }
        }

        # Event definition lookup by logid
        $msgID = Get-FortiLogMessageID -LogID $data.logid
        if ($msgID) {
            $def = Get-EventDefinition -LogID $data.logid
            if ($def) {
                # Contextual enhancements
                $desc = $def.Desc
                $sev = $def.Sev

                if ($data.logid -eq '0100032695') {
                    if ($data.msg -match 'down') { $desc = 'Switch Port Down'; $sev = 'Warning' }
                    elseif ($data.msg -match 'up') { $desc = 'Switch Port Up'; $sev = 'Info' }
                }

                $eventObj = [PSCustomObject]@{
                    DateTime = "$($data.date) $($data.time)"
                    Device   = $data.devname
                    Source   = if ($data.ap) { $data.ap } elseif ($data.switchid) { $data.switchid } else { 'N/A' }
                    Message  = $data.msg
                    Desc     = $desc
                    Severity = $sev
                    Category = $def.Cat
                    LogID    = $data.logid
                }

                switch ($def.Cat) {
                    'System'   { $Results.SystemEvents.Add($eventObj) }
                    'Switch'   { $Results.SwitchEvents.Add($eventObj) }
                    'Wireless' { $Results.WirelessEvents.Add($eventObj) }
                    'SDWAN'    { $Results.SDWANEvents.Add($eventObj) }
                    'Hardware' { $Results.HardwareEvents.Add($eventObj); $Results.SDWANEvents.Add($eventObj) }
                    'VPN'      { $Results.VPNEvents.Add($eventObj) }
                    'Router'   { $Results.RouterEvents.Add($eventObj) }
                    'User'     { $Results.UserEvents.Add($eventObj) }
                }
                continue
            }
        }

        # Heuristic AP reboot detection (wireless subtype, low remotewtptime)
        if ($data.subtype -eq 'wireless' -and $data.remotewtptime) {
            $uptime = 0.0
            if ([double]::TryParse($data.remotewtptime, [ref]$uptime) -and $uptime -gt 0 -and $uptime -lt $RebootThreshold) {
                $key = "$($data.date)_$($data.time)_$($data.ap)_reboot"
                if ($heuristicRebootKeys.Add($key)) {
                    $Results.WirelessEvents.Add([PSCustomObject]@{
                        DateTime = "$($data.date) $($data.time)"
                        Device   = $data.devname
                        Source   = $data.ap
                        Message  = "Detected low uptime ($($data.remotewtptime)s)"
                        Desc     = 'AP Reboot (Heuristic)'
                        Severity = 'Critical'
                        Category = 'Wireless'
                        LogID    = $data.logid
                    })
                }
            }
        }

        # Excessive frame failure detection
        if ($data.subtype -eq 'wireless' -and $script:RegexPatterns.FrameFail.IsMatch($line)) {
            $Results.FrameFailures.Add([PSCustomObject]@{
                DateTime  = "$($data.date) $($data.time)"
                Device    = $data.devname
                Source    = $data.ap
                ClientMAC = $data.stamac
                Message   = $data.msg
                Desc      = 'Excessive Frame Failures'
                Severity  = 'Warning'
                LogID     = $data.logid
            })
        }
    }

    return $Results
}

# ============================================================================
# RECOMMENDATIONS ENGINE
# ============================================================================

function New-FortiRecommendation {
    <#
    .SYNOPSIS
        Generates actionable recommendations based on analysis results.
    .PARAMETER Results
        Analysis results hashtable from Get-FortiAnalysisResults.
    .PARAMETER HighRFThreshold
        Frame failure count to trigger HIGH RF warning. Default: 20.
    .PARAMETER RebootWarningThreshold
        Reboot count to trigger WARNING. Default: 1.
    .OUTPUTS
        Array of PSCustomObject with Level and Message properties.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results,

        [int]$HighRFThreshold = 20,
        [int]$RebootWarningThreshold = 1
    )

    $recs = [System.Collections.Generic.List[object]]::new()
    $add = { param($level, $msg) $recs.Add([PSCustomObject]@{ Level = $level; Message = $msg }) }

    # System events
    if ($Results.SystemEvents) {
        $crashes = @($Results.SystemEvents | Where-Object { $_.Desc -match 'Crash|Reset by Watchdog' })
        if ($crashes.Count -gt 0) {
            & $add 'Critical' "SYSTEM CRASH: $($crashes.Count) watchdog reset(s) detected. Check firmware and hardware health."
        }

        $haFails = @($Results.SystemEvents | Where-Object { $_.Desc -match 'HA Failover|HA Sync Failed|HA Heartbeat Lost|Monitor Interface Down' })
        if ($haFails.Count -gt 0) {
            & $add 'Critical' "HA INSTABILITY: $($haFails.Count) HA event(s). Verify cluster configuration and heartbeat links."
        }

        $conserve = @($Results.SystemEvents | Where-Object { $_.Desc -match 'Conserve Mode' })
        if ($conserve.Count -gt 0) {
            & $add 'Warning' "MEMORY/CPU: $($conserve.Count) conserve mode event(s). Check resource utilization."
        }

        $intDown = @($Results.SystemEvents | Where-Object { $_.Desc -match 'Interface Link Down' })
        if ($intDown.Count -gt 0) {
            & $add 'Critical' "INTERFACE DOWN: $($intDown.Count) interface link-down event(s). Check physical connectivity."
        }

        $diskLow = @($Results.SystemEvents | Where-Object { $_.Desc -match 'Disk Space Low' })
        if ($diskLow.Count -gt 0) {
            & $add 'Warning' "STORAGE: $($diskLow.Count) disk space low warning(s). Clean up logs or expand storage."
        }

        $licenseIssues = @($Results.SystemEvents | Where-Object { $_.Desc -match 'License (Expired|Expiring)' })
        if ($licenseIssues.Count -gt 0) {
            & $add 'Critical' "LICENSING: $($licenseIssues.Count) license issue(s). Renew subscriptions immediately."
        }

        $certExpiry = @($Results.SystemEvents | Where-Object { $_.Desc -match 'Certificate Expiry' })
        if ($certExpiry.Count -gt 0) {
            & $add 'Warning' "CERTIFICATES: $($certExpiry.Count) certificate expiry warning(s). Renew certificates."
        }
    }

    # Hardware events
    if ($Results.HardwareEvents) {
        $fanTemp = @($Results.HardwareEvents | Where-Object { $_.Desc -match 'Fan|Temp' })
        if ($fanTemp.Count -gt 0) {
            & $add 'Critical' "HARDWARE: $($fanTemp.Count) fan/temperature alarm(s). Check cooling and environment."
        }
    }

    # Switch events
    if ($Results.SwitchEvents) {
        $switchOff = @($Results.SwitchEvents | Where-Object { $_.Desc -match 'Offline|Tunnel Down' })
        if ($switchOff.Count -gt 0) {
            & $add 'Critical' "SWITCH OFFLINE: $($switchOff.Count) switch offline event(s). Check CAPWAP tunnels and uplinks."
        }

        $poeIssues = @($Results.SwitchEvents | Where-Object { $_.Desc -match 'PoE' })
        if ($poeIssues.Count -gt 0) {
            & $add 'Warning' "POE: $($poeIssues.Count) PoE event(s). Check power budget and cable integrity."
        }

        $stpChanges = @($Results.SwitchEvents | Where-Object { $_.Desc -match 'STP|Spanning Tree' })
        if ($stpChanges.Count -gt 5) {
            & $add 'Warning' "STP INSTABILITY: $($stpChanges.Count) topology changes. Review spanning tree configuration."
        }

        $portSec = @($Results.SwitchEvents | Where-Object { $_.Desc -match 'Port Security Violation|Error Disabled' })
        if ($portSec.Count -gt 0) {
            & $add 'Critical' "PORT SECURITY: $($portSec.Count) violation(s). Check for rogue devices or misconfigurations."
        }
    }

    # Wireless events
    if ($Results.WirelessEvents) {
        $apReboots = @($Results.WirelessEvents | Where-Object { $_.Desc -match 'Reboot' })
        if ($apReboots.Count -ge $RebootWarningThreshold) {
            & $add 'Critical' "AP REBOOTS: $($apReboots.Count) reboot(s) detected. Check PoE budget, firmware, and power supply."
        }

        $apOffline = @($Results.WirelessEvents | Where-Object { $_.Desc -match 'Left Controller|Offline|Tunnel Down' })
        if ($apOffline.Count -gt 0) {
            & $add 'Warning' "AP CONNECTIVITY: $($apOffline.Count) AP offline/tunnel-down event(s)."
        }

        $rogueAPs = @($Results.WirelessEvents | Where-Object { $_.Desc -match 'Rogue Detected' })
        if ($rogueAPs.Count -gt 0) {
            & $add 'Critical' "ROGUE AP: $($rogueAPs.Count) rogue AP(s) detected. Investigate immediately."
        }

        $fwFail = @($Results.WirelessEvents | Where-Object { $_.Desc -match 'Firmware.*Failed|Image.*Failed' })
        if ($fwFail.Count -gt 0) {
            & $add 'Critical' "FIRMWARE: $($fwFail.Count) AP firmware/image upgrade failure(s)."
        }

        $radioIssues = @($Results.WirelessEvents | Where-Object { $_.Desc -match 'Interference|Radio Disabled|Radar' })
        if ($radioIssues.Count -gt 0) {
            & $add 'Warning' "RF ENVIRONMENT: $($radioIssues.Count) radio issue(s). Review channel plan and RF environment."
        }
    }

    # Frame failures
    if ($Results.FrameFailures.Count -ge $HighRFThreshold) {
        & $add 'Warning' "RF QUALITY: $($Results.FrameFailures.Count) frame failure(s). Check interference, antennas, and channel utilization."
    } elseif ($Results.FrameFailures.Count -gt 0) {
        & $add 'Info' "RF: $($Results.FrameFailures.Count) minor frame failure(s). Monitor trends."
    }

    # SD-WAN events
    if ($Results.SDWANEvents) {
        $slaFails = @($Results.SDWANEvents | Where-Object { $_.Desc -match 'SLA Failed|Member Down|Health Check Failed' })
        if ($slaFails.Count -gt 0) {
            & $add 'Warning' "SD-WAN: $($slaFails.Count) SLA/member failure(s). Check ISP links and health checks."
        }
    }

    # VPN events
    if ($Results.VPNEvents) {
        $vpnDown = @($Results.VPNEvents | Where-Object { $_.Desc -match 'Tunnel Down|Failed' })
        if ($vpnDown.Count -gt 0) {
            & $add 'Warning' "VPN: $($vpnDown.Count) VPN tunnel failure(s). CheckIKE/IPsec configuration and peer status."
        }
    }

    # User events
    if ($Results.UserEvents) {
        $authFails = @($Results.UserEvents | Where-Object { $_.Desc -match 'Login Failed|Locked Out' })
        if ($authFails.Count -gt 10) {
            & $add 'Warning' "AUTH: $($authFails.Count) authentication failure(s). Check for brute-force attempts or misconfigured credentials."
        }
    }

    # All clear
    $totalCritical = $recs | Where-Object { $_.Level -eq 'Critical' }
    $totalWarning  = $recs | Where-Object { $_.Level -eq 'Warning' }
    if ($totalCritical.Count -eq 0 -and $totalWarning.Count -eq 0) {
        & $add 'OK' 'No critical infrastructure issues detected. Continue regular monitoring.'
    }

    return $recs
}

# ============================================================================
# REPORTING / EXPORT
# ============================================================================

function Export-FortiReport {
    <#
    .SYNOPSIS
        Exports analysis results in multiple formats.
    .PARAMETER Results
        Analysis results hashtable.
    .PARAMETER Recommendations
        Recommendations array from New-FortiRecommendation.
    .PARAMETER OutputPath
        Base output path (extension determines format, or -Format overrides).
    .PARAMETER Format
        Export format: Text, HTML, JSON, CSV. Default: auto-detect from extension.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results,

        [Parameter(Mandatory)]
        [array]$Recommendations,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [ValidateSet('Text', 'HTML', 'JSON', 'CSV')]
        [string]$Format
    )

    # Auto-detect format from extension
    if (-not $Format) {
        $ext = [System.IO.Path]::GetExtension($OutputPath).ToLower()
        $Format = switch ($ext) {
            '.html' { 'HTML' }
            '.json' { 'JSON' }
            '.csv'  { 'CSV' }
            default { 'Text' }
        }
    }

    if (-not $PSCmdlet.ShouldProcess($OutputPath, "Export $Format report")) { return }

    $allEvents = @()
    $allEvents += $Results.SystemEvents
    $allEvents += $Results.SwitchEvents
    $allEvents += $Results.WirelessEvents
    $allEvents += $Results.SDWANEvents
    $allEvents += $Results.HardwareEvents
    $allEvents += $Results.VPNEvents
    $allEvents += $Results.RouterEvents
    $allEvents += $Results.UserEvents
    $allEvents += $Results.FrameFailures

    switch ($Format) {
        'JSON' {
            $export = @{
                Generated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Summary   = $Results.Summary
                Events    = $allEvents
                Recommendations = $Recommendations
            }
            $export | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        'CSV' {
            $allEvents | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
        'HTML' {
            $htmlHead = @"
<style>
  body { font-family: Segoe UI, sans-serif; margin: 20px; background: #1e1e1e; color: #ddd; }
  h1 { color: #007acc; }
  h2 { color: #569cd6; border-bottom: 1px solid #444; padding-bottom: 5px; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
  th { background: #264f78; color: white; padding: 8px 12px; text-align: left; }
  td { border: 1px solid #444; padding: 6px 12px; }
  tr:nth-child(even) { background: #2d2d30; }
  .critical { color: #f44; font-weight: bold; }
  .warning { color: #fc0; }
  .info { color: #5cf; }
  .ok { color: #5f5; }
  .summary-card { display: inline-block; background: #2d2d30; padding: 15px 25px; margin: 5px; border-radius: 6px; border-left: 4px solid #007acc; }
  .summary-value { font-size: 28px; font-weight: bold; color: #007acc; }
  .summary-label { font-size: 12px; color: #aaa; }
</style>
"@
            $summaryCards = @"
<div class="summary-card"><div class="summary-value">$($Results.SystemEvents.Count)</div><div class="summary-label">System/HA Events</div></div>
<div class="summary-card"><div class="summary-value">$($Results.SwitchEvents.Count)</div><div class="summary-label">Switch Events</div></div>
<div class="summary-card"><div class="summary-value">$($Results.WirelessEvents.Count)</div><div class="summary-label">Wireless Events</div></div>
<div class="summary-card"><div class="summary-value">$($Results.FrameFailures.Count)</div><div class="summary-label">Frame Failures</div></div>
<div class="summary-card"><div class="summary-value">$($Results.HardwareEvents.Count)</div><div class="summary-label">Hardware Alarms</div></div>
<div class="summary-card"><div class="summary-value">$($Results.SDWANEvents.Count)</div><div class="summary-label">SD-WAN Events</div></div>
<div class="summary-card"><div class="summary-value">$($Results.VPNEvents.Count)</div><div class="summary-label">VPN Events</div></div>
<div class="summary-card"><div class="summary-value">$($Results.RouterEvents.Count)</div><div class="summary-label">Router Events</div></div>
"@
            $recHtml = ($Recommendations | ForEach-Object {
                $cls = switch ($_.Level) { 'Critical' { 'critical' } 'Warning' { 'warning' } 'OK' { 'ok' } default { 'info' } }
                "<p class='$cls'>[$($_.Level)] $($_.Message)</p>"
            }) -join "`n"

            $eventTable = if ($allEvents.Count -gt 0) {
                $rows = ($allEvents | Sort-Object DateTime -Descending | Select-Object -First 200 | ForEach-Object {
                    "<tr><td>$($_.DateTime)</td><td>$($_.Severity)</td><td>$($_.Category)</td><td>$($_.Desc)</td><td>$($_.Source)</td><td>$($_.Device)</td><td>$($_.Message)</td></tr>"
                }) -join "`n"
                @"
<table>
<tr><th>Time</th><th>Severity</th><th>Category</th><th>Event</th><th>Source</th><th>Device</th><th>Message</th></tr>
$rows
</table>
"@
            } else { "<p>No events found.</p>" }

            $html = @"
<!DOCTYPE html>
<html><head><title>FortiAnalyzer Report - $(Get-Date -Format 'yyyy-MM-dd')</title>$htmlHead</head>
<body>
<h1>FortiAnalyzer Infrastructure Report</h1>
<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Total Lines: $($Results.Summary.TotalLines)</p>
$summaryCards
<h2>Recommendations</h2>
$recHtml
<h2>Events (Top 200)</h2>
$eventTable
</body></html>
"@
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        'Text' {
            $sb = [System.Text.StringBuilder]::new()
            [void]$sb.AppendLine('=' * 70)
            [void]$sb.AppendLine('FORTIANALYZER INFRASTRUCTURE ANALYSIS REPORT')
            [void]$sb.AppendLine('=' * 70)
            [void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            [void]$sb.AppendLine("Total Lines: $($Results.Summary.TotalLines)")
            if ($Results.Summary.DeviceFilter) { [void]$sb.AppendLine("Device Filter: $($Results.Summary.DeviceFilter)") }
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('-' * 70)
            [void]$sb.AppendLine('SUMMARY')
            [void]$sb.AppendLine('-' * 70)
            [void]$sb.AppendLine("  System/HA Events:  $($Results.SystemEvents.Count)")
            [void]$sb.AppendLine("  Switch Events:     $($Results.SwitchEvents.Count)")
            [void]$sb.AppendLine("  Wireless Events:   $($Results.WirelessEvents.Count)")
            [void]$sb.AppendLine("  SD-WAN Events:     $($Results.SDWANEvents.Count)")
            [void]$sb.AppendLine("  Hardware Events:   $($Results.HardwareEvents.Count)")
            [void]$sb.AppendLine("  VPN Events:        $($Results.VPNEvents.Count)")
            [void]$sb.AppendLine("  Router Events:     $($Results.RouterEvents.Count)")
            [void]$sb.AppendLine("  Frame Failures:    $($Results.FrameFailures.Count)")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('-' * 70)
            [void]$sb.AppendLine('RECOMMENDATIONS')
            [void]$sb.AppendLine('-' * 70)
            foreach ($r in $Recommendations) {
                [void]$sb.AppendLine("  [$($r.Level)] $($r.Message)")
            }
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('-' * 70)
            [void]$sb.AppendLine('EVENTS (Top 50)')
            [void]$sb.AppendLine('-' * 70)
            foreach ($evt in ($allEvents | Sort-Object DateTime -Descending | Select-Object -First 50)) {
                [void]$sb.AppendLine("  [$($evt.Severity)] $($evt.DateTime) | $($evt.Category) | $($evt.Desc) | $($evt.Source) | $($evt.Message)")
            }
            $sb.ToString() | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }
}

function Export-FortiReportHtml {
    param([hashtable]$Results, [array]$Recommendations, [string]$OutputPath)
    Export-FortiReport -Results $Results -Recommendations $Recommendations -OutputPath $OutputPath -Format 'HTML'
}

function Export-FortiReportJson {
    param([hashtable]$Results, [array]$Recommendations, [string]$OutputPath)
    Export-FortiReport -Results $Results -Recommendations $Recommendations -OutputPath $OutputPath -Format 'JSON'
}

function Export-FortiReportCsv {
    param([hashtable]$Results, [array]$Recommendations, [string]$OutputPath)
    Export-FortiReport -Results $Results -Recommendations $Recommendations -OutputPath $OutputPath -Format 'CSV'
}

# ============================================================================
# CONSOLE OUTPUT HELPERS
# ============================================================================

function Write-FortiStatus {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Header')]
        [string]$Level = 'Info'
    )
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Header'  { 'White' }
    }
    Write-Host $Message -ForegroundColor $color
}

function Write-FortiDashboard {
    param([hashtable]$Results)

    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor White
    Write-Host '  FORTIANALYZER INFRASTRUCTURE DASHBOARD' -ForegroundColor Green
    Write-Host ('=' * 70) -ForegroundColor White

    $categories = @(
        @{ Name = 'System/HA'; Events = $Results.SystemEvents; Emoji = '[SYS]' }
        @{ Name = 'Switch';    Events = $Results.SwitchEvents; Emoji = '[SWI]' }
        @{ Name = 'Wireless';  Events = $Results.WirelessEvents; Emoji = '[WLS]' }
        @{ Name = 'SD-WAN';    Events = $Results.SDWANEvents; Emoji = '[SDW]' }
        @{ Name = 'Hardware';  Events = $Results.HardwareEvents; Emoji = '[HWR]' }
        @{ Name = 'VPN';       Events = $Results.VPNEvents; Emoji = '[VPN]' }
        @{ Name = 'Router';    Events = $Results.RouterEvents; Emoji = '[RTR]' }
        @{ Name = 'User';      Events = $Results.UserEvents; Emoji = '[USR]' }
    )

    foreach ($cat in $categories) {
        $count = $cat.Events.Count
        $critical = if ($cat.Events) { ($cat.Events | Where-Object { $_.Severity -eq 'Critical' }).Count } else { 0 }
        $warning = if ($cat.Events) { ($cat.Events | Where-Object { $_.Severity -eq 'Warning' }).Count } else { 0 }

        $status = if ($critical -gt 0) { 'CRITICAL' } elseif ($warning -gt 0) { 'WARNING' } elseif ($count -gt 0) { 'INFO' } else { 'HEALTHY' }
        $statusColor = switch ($status) {
            'CRITICAL' { 'Red' }
            'WARNING'  { 'Yellow' }
            'INFO'     { 'Cyan' }
            'HEALTHY'  { 'Green' }
        }

        Write-Host "  $($cat.Emoji) $($cat.Name): " -NoNewline -ForegroundColor Gray
        Write-Host "$status " -NoNewline -ForegroundColor $statusColor
        Write-Host "($count events)" -ForegroundColor DarkGray
    }

    # Frame failures
    $rfCount = $Results.FrameFailures.Count
    $rfStatus = if ($rfCount -gt 20) { 'POOR' } elseif ($rfCount -gt 0) { 'WARNING' } else { 'GOOD' }
    $rfColor = switch ($rfStatus) { 'POOR' { 'Red' } 'WARNING' { 'Yellow' } default { 'Green' } }
    Write-Host "  [RF ] RF Health:        " -NoNewline -ForegroundColor Gray
    Write-Host "$rfStatus " -NoNewline -ForegroundColor $rfColor
    Write-Host "($rfCount failures)" -ForegroundColor DarkGray

    Write-Host ('=' * 70) -ForegroundColor White
}

# ============================================================================
# MODULE EXPORTS
# ============================================================================
Export-ModuleMember -Function @(
    'ConvertFrom-FortiLogLine',
    'Get-FortiLogMessageID',
    'Get-EventDefinition',
    'Get-FortiAnalysisResults',
    'New-FortiRecommendation',
    'Export-FortiReport',
    'Export-FortiReportHtml',
    'Export-FortiReportJson',
    'Export-FortiReportCsv',
    'Write-FortiStatus',
    'Write-FortiDashboard'
)
