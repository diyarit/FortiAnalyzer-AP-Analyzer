<#
.SYNOPSIS
    FortiAnalyzer Infrastructure Analyzer - GUI Edition (Enterprise Optimized)
    
.DESCRIPTION
    Modern WPF GUI for analyzing FortiAnalyzer logs.
    Includes advanced detection for HA, SD-WAN, Hardware Health (Fan/Temp), and Switch STP.
    
.NOTES
    Version: 2.5 (Enterprise)
    Requires: PowerShell 5.1+
#>

# Load WPF Assemblies
Add-Type -AssemblyName PresentationFramework

# ==============================================================================
# XAML UI DEFINITION
# ==============================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FortiAnalyzer Infrastructure Analyzer (Enterprise)" Height="768" Width="1024"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E">
    
    <Window.Resources>
        <!-- Styles -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#DDDDDD"/>
            <Setter Property="BorderBrush" Value="#444444"/>
            <Setter Property="Margin" Value="5"/>
        </Style>

        <Style TargetType="ListView">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="#EEEEEE"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>

        <Style TargetType="GridViewColumnHeader">
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Background" Value="#333333"/>
            <Setter Property="Foreground" Value="#EEEEEE"/>
            <Setter Property="Padding" Value="5"/>
        </Style>
    </Window.Resources>

    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header/Input -->
            <RowDefinition Height="Auto"/> <!-- Dashboard Cards -->
            <RowDefinition Height="*"/>    <!-- Tabs -->
            <RowDefinition Height="Auto"/> <!-- Status Bar -->
        </Grid.RowDefinitions>

        <!-- INPUT SECTION -->
        <Border Grid.Row="0" BorderBrush="#444444" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,0,0,15" Background="#252526">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Label Content="Log Path:" Foreground="#AAAAAA" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtLogPath" Grid.Row="0" Grid.Column="1" Margin="5,2" Background="#333333" Foreground="White" BorderThickness="0" Padding="8"/>
                <Button Name="btnBrowse" Content="..." Grid.Row="0" Grid.Column="2" Width="40" Margin="5,2" Background="#444444"/>
                
                <Label Content="Device Filter:" Foreground="#AAAAAA" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtDeviceFilter" Grid.Row="1" Grid.Column="1" Margin="5,2" Background="#333333" Foreground="White" BorderThickness="0" Padding="8" ToolTip="Optional: Enter hostname to filter"/>
                
                <StackPanel Orientation="Horizontal" Grid.Row="0" Grid.RowSpan="2" Grid.Column="3" VerticalAlignment="Center" Margin="15,0,0,0">
                    <Button Name="btnAnalyze" Content="RUN ANALYSIS" FontSize="14" Padding="25,12" Background="#007ACC"/>
                    <Button Name="btnExport" Content="Export Report" Margin="10,0,0,0" Background="#444444"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- DASHBOARD CARDS (2 Rows) -->
        <Grid Grid.Row="1" Margin="0,0,0,15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Row 1 Cards -->
            <Border Grid.Row="0" Grid.Column="0" Background="#2D2D30" CornerRadius="4" Margin="0,0,5,5" Padding="15">
                <StackPanel>
                    <TextBlock Text="SYSTEM &amp; HA" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblSystemStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblSystemCount" Text="0 events" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="1" Background="#2D2D30" CornerRadius="4" Margin="5,0,5,5" Padding="15">
                <StackPanel>
                    <TextBlock Text="SWITCH INFRA" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblSwitchStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblSwitchCount" Text="0 events" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="2" Background="#2D2D30" CornerRadius="4" Margin="5,0,5,5" Padding="15">
                <StackPanel>
                    <TextBlock Text="WIRELESS / APs" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblWirelessStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblWirelessCount" Text="0 events" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="3" Background="#2D2D30" CornerRadius="4" Margin="5,0,0,5" Padding="15">
                <StackPanel>
                    <TextBlock Text="RF HEALTH" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblRFStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblRFCount" Text="0 failures" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

            <!-- Row 2 Cards (Advanced) -->
             <Border Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Background="#2D2D30" CornerRadius="4" Margin="0,5,5,0" Padding="15">
                <StackPanel>
                    <TextBlock Text="SD-WAN &amp; UPLINKS" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblSDWANStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblSDWANCount" Text="0 SLA failures" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Background="#2D2D30" CornerRadius="4" Margin="5,5,0,0" Padding="15">
                <StackPanel>
                    <TextBlock Text="HARDWARE (FAN/TEMP)" Foreground="#AAAAAA" FontSize="11" FontWeight="Bold"/>
                    <TextBlock Name="lblHardwareStatus" Text="WAITING" Foreground="Gray" FontSize="20" FontWeight="Bold" Margin="0,5,0,0"/>
                    <TextBlock Name="lblHardwareCount" Text="0 alarms" Foreground="Gray" FontSize="12"/>
                </StackPanel>
            </Border>

        </Grid>

        <!-- TABS -->
        <TabControl Grid.Row="2" Background="#1E1E1E" BorderThickness="0">
            <TabControl.Resources>
                <Style TargetType="TabItem">
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="TabItem">
                                <Border Name="Border" Background="#2D2D30" Margin="0,0,2,0" CornerRadius="4,4,0,0">
                                    <ContentPresenter x:Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header" Margin="20,10"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter TargetName="Border" Property="Background" Value="#007ACC"/>
                                        <Setter Property="Foreground" Value="White"/>
                                    </Trigger>
                                    <Trigger Property="IsSelected" Value="False">
                                        <Setter Property="Foreground" Value="#AAAAAA"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </TabControl.Resources>

            <TabItem Header="Recommendations">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Name="panelRecommendations" Margin="10">
                        <TextBlock Text="Run analysis to see recommendations." Foreground="#777" FontSize="14" HorizontalAlignment="Center" Margin="0,50,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="System &amp; HA">
                <ListView Name="lvSystem">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Event" Width="220" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Device" Width="120" DisplayMemberBinding="{Binding Device}"/>
                            <GridViewColumn Header="Message" Width="450" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>

            <TabItem Header="Switch Events">
                <ListView Name="lvSwitch">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Event" Width="200" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Source" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="450" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>
            
             <TabItem Header="SD-WAN &amp; HW">
                <ListView Name="lvSDWAN">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Category" Width="100" DisplayMemberBinding="{Binding Category}"/>
                            <GridViewColumn Header="Event" Width="200" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Message" Width="450" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>

            <TabItem Header="Wireless Events">
                <ListView Name="lvWireless">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Event" Width="200" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="AP Name" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="450" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>
            
            <TabItem Header="All Logs (Raw)">
                 <TextBox Name="txtRawLogs" Background="#1E1E1E" Foreground="#CCCCCC" FontFamily="Consolas" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" BorderThickness="0"/>
            </TabItem>
        </TabControl>

        <!-- STATUS BAR -->
        <StatusBar Grid.Row="3" Background="#007ACC" Foreground="White">
            <StatusBarItem>
                <TextBlock Name="lblStatus" Text="Ready"/>
            </StatusBarItem>
            <StatusBarItem HorizontalAlignment="Right">
                <ProgressBar Name="progBar" Width="150" Height="10" Visibility="Collapsed" IsIndeterminate="True"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# ==============================================================================
# OPTIMIZED ANALYSIS LOGIC (Type-First Filtering)
# ==============================================================================

# Critical Log Definitions (Grouped by Type/Subtype for speed)
$EventDefinitions = @{
    # System & HA (subtype=system OR subtype=ha)
    '32009' = @{ Cat="System"; Sev="Info";     Desc="System Started (Reboot/Power-on)" }
    '32200' = @{ Cat="System"; Sev="Critical"; Desc="System Shutdown (Controlled)" }
    '32003' = @{ Cat="System"; Sev="Critical"; Desc="System Reset by Watchdog (Crash)" }
    '22011' = @{ Cat="System"; Sev="Warning";  Desc="Entered Conserve Mode (Mem/CPU)" }
    '22012' = @{ Cat="System"; Sev="Info";     Desc="Exited Conserve Mode" }
    '35016' = @{ Cat="System"; Sev="Warning";  Desc="HA Failover Success" }
    '35013' = @{ Cat="System"; Sev="Critical"; Desc="HA Failover Failed" }
    '35011' = @{ Cat="System"; Sev="Critical"; Desc="HA Sync Failed" }
    '22108' = @{ Cat="Hardware"; Sev="Critical"; Desc="Fan Failure/Anomaly" }
    '22109' = @{ Cat="Hardware"; Sev="Critical"; Desc="Temperature High (Overheat)" }

    # Wireless (subtype=wireless)
    '43551' = @{ Cat="Wireless"; Sev="Info";     Desc="AP Joined Controller" }
    '43552' = @{ Cat="Wireless"; Sev="Warning";  Desc="AP Left Controller (Offline)" }
    '43555' = @{ Cat="Wireless"; Sev="Critical"; Desc="AP Rebooted (WTP Reset)" }
    '43527' = @{ Cat="Wireless"; Sev="Warning";  Desc="CAPWAP Tunnel Down" }
    '43556' = @{ Cat="Wireless"; Sev="Warning";  Desc="Radar Detected (DFS)" }
    '43548' = @{ Cat="Wireless"; Sev="Warning";  Desc="Radio Interference" }

    # Switch (subtype=switch-controller OR subtype=system)
    '32605' = @{ Cat="Switch"; Sev="Info";     Desc="Switch Online (Joined)" }
    '32606' = @{ Cat="Switch"; Sev="Critical"; Desc="Switch Offline (Tunnel Down)" }
    '32694' = @{ Cat="Switch"; Sev="Warning";  Desc="Switch PoE Error" }
    '32695' = @{ Cat="Switch"; Sev="Info";     Desc="Switch Port Link Status" }
    '32696' = @{ Cat="Switch"; Sev="Warning";  Desc="STP Topology Change" }

    # SD-WAN (subtype=sdwan)
    '22931' = @{ Cat="SDWAN"; Sev="Warning";   Desc="SD-WAN SLA Failed (Packet Loss/Latency)" }
}

function Parse-FortiLogLine {
    param([string]$LogLine)
    $logData = @{}
    $pattern = '([a-zA-Z0-9_]+)=(?:"([^"]*)"|([^"\s]+))'
    $matches = [regex]::Matches($LogLine, $pattern)
    foreach ($match in $matches) {
        $key = $match.Groups[1].Value
        $value = if ($match.Groups[2].Success) { $match.Groups[2].Value } else { $match.Groups[3].Value }
        $logData[$key] = $value
    }
    return $logData
}

function Get-LogMessageID {
    param([string]$LogID)
    if ([string]::IsNullOrEmpty($LogID) -or $LogID.Length -lt 5) { return $null }
    return $LogID.Substring($LogID.Length - 5)
}

function Run-Analysis {
    param($FilePath, $DeviceFilter)
    
    $Results = @{
        SystemEvents = @()
        SwitchEvents = @()
        WirelessEvents = @()
        SDWANEvents = @()
        HardwareEvents = @()
        FrameFailures = @()
    }

    $lines = Get-Content $FilePath
    if ($DeviceFilter) {
        $lines = $lines | Where-Object { $_ -match $DeviceFilter }
    }

    foreach ($line in $lines) {
        # Quick pre-check for key types (Optimization)
        if ($line -notmatch "logid=") { continue }

        $data = Parse-FortiLogLine $line
        $subtype = $data.subtype
        
        # 1. Main Infrastructure Check
        if ($data.ContainsKey('logid')) {
            $msgID = Get-LogMessageID $data.logid
            
            if ($EventDefinitions.ContainsKey($msgID)) {
                $def = $EventDefinitions[$msgID]
                $desc = $def.Desc
                $sev = $def.Sev
                
                # Contextual Enhancements
                if ($msgID -eq '32695') {
                    if ($data.msg -match "down") { $desc="Switch Port Down"; $sev="Warning" }
                    elseif ($data.msg -match "up") { $desc="Switch Port Up"; $sev="Info" }
                }

                $eventObj = [PSCustomObject]@{
                    DateTime = "$($data.date) $($data.time)"
                    Device   = $data.devname
                    Source   = if ($data.ap) { $data.ap } elseif ($data.switchid) { $data.switchid } else { "N/A" }
                    Message  = $data.msg
                    Desc     = $desc
                    Severity = $sev
                    Category = $def.Cat
                }

                switch ($def.Cat) {
                    "System"   { $Results.SystemEvents += $eventObj }
                    "Switch"   { $Results.SwitchEvents += $eventObj }
                    "Wireless" { $Results.WirelessEvents += $eventObj }
                    "SDWAN"    { $Results.SDWANEvents += $eventObj }
                    "Hardware" { $Results.HardwareEvents += $eventObj; $Results.SDWANEvents += $eventObj } # Show HW in Mixed Tab
                }
            }
        }
        
        # 2. RF Failures (Wireless Only)
        if ($subtype -eq "wireless" -and $line -match "client-disconnected-by-wtp.*excessive.*frames") {
            $Results.FrameFailures += 1
        }
        
        # 3. Heuristic Reboot (Wireless Only)
        if ($subtype -eq "wireless" -and $data.remotewtptime -and [double]$data.remotewtptime -lt 30.0 -and [double]$data.remotewtptime -gt 0) {
            $isDuplicate = $false
            foreach ($e in $Results.WirelessEvents) {
                if ($e.Desc -like "*Reboot*" -and $e.Source -eq $data.ap -and $e.DateTime -eq "$($data.date) $($data.time)") {
                    $isDuplicate = $true; break
                }
            }
            if (-not $isDuplicate) {
                $Results.WirelessEvents += [PSCustomObject]@{
                    DateTime = "$($data.date) $($data.time)"
                    Device   = $data.devname
                    Source   = $data.ap
                    Message  = "Detected low uptime ($($data.remotewtptime)s)"
                    Desc     = "AP Reboot (Heuristic)"
                    Severity = "Critical"
                }
            }
        }
    }
    return $Results
}

# ==============================================================================
# UI INITIALIZATION & EVENTS
# ==============================================================================

# Parse XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Map Controls
$btnBrowse = $window.FindName("btnBrowse")
$btnAnalyze = $window.FindName("btnAnalyze")
$btnExport = $window.FindName("btnExport")
$txtLogPath = $window.FindName("txtLogPath")
$txtDeviceFilter = $window.FindName("txtDeviceFilter")
$lvSystem = $window.FindName("lvSystem")
$lvSwitch = $window.FindName("lvSwitch")
$lvWireless = $window.FindName("lvWireless")
$lvSDWAN = $window.FindName("lvSDWAN")
$panelRecs = $window.FindName("panelRecommendations")
$lblStatus = $window.FindName("lblStatus")
$progBar = $window.FindName("progBar")
$txtRawLogs = $window.FindName("txtRawLogs")

# Dashboard Labels
$lblSystemStatus = $window.FindName("lblSystemStatus")
$lblSwitchStatus = $window.FindName("lblSwitchStatus")
$lblWirelessStatus = $window.FindName("lblWirelessStatus")
$lblRFStatus = $window.FindName("lblRFStatus")
$lblSDWANStatus = $window.FindName("lblSDWANStatus")
$lblHardwareStatus = $window.FindName("lblHardwareStatus")

# --- Event Handlers ---

$btnBrowse.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "Log Files (*.log;*.txt)|*.log;*.txt|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq $true) {
        $txtLogPath.Text = $dlg.FileName
    }
})

$btnAnalyze.Add_Click({
    $path = $txtLogPath.Text
    if (-not (Test-Path $path)) {
        [System.Windows.MessageBox]::Show("Please select a valid log file.", "Error", "OK", "Error")
        return
    }

    # Reset UI
    $lblStatus.Text = "Analyzing..."
    $progBar.Visibility = "Visible"
    $lvSystem.ItemsSource = $null
    $lvSwitch.ItemsSource = $null
    $lvWireless.ItemsSource = $null
    $lvSDWAN.ItemsSource = $null
    $panelRecs.Children.Clear()
    
    # Force UI update
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Run Analysis
        $results = Run-Analysis -FilePath $path -DeviceFilter $txtDeviceFilter.Text
        
        # Update Lists
        $lvSystem.ItemsSource = $results.SystemEvents
        $lvSwitch.ItemsSource = $results.SwitchEvents
        $lvWireless.ItemsSource = $results.WirelessEvents
        $lvSDWAN.ItemsSource = $results.SDWANEvents
        
        # Update Dashboard
        Update-DashboardCard $lblSystemStatus $results.SystemEvents
        Update-DashboardCard $lblSwitchStatus $results.SwitchEvents
        Update-DashboardCard $lblWirelessStatus $results.WirelessEvents
        Update-DashboardCard $lblSDWANStatus $results.SDWANEvents
        Update-DashboardCard $lblHardwareStatus $results.HardwareEvents
        
        # RF Health
        $rfCount = $results.FrameFailures.Count
        if ($rfCount -gt 20) { 
            $lblRFStatus.Text = "POOR"; $lblRFStatus.Foreground = "Red" 
        } elseif ($rfCount -gt 0) { 
            $lblRFStatus.Text = "WARNING"; $lblRFStatus.Foreground = "Yellow" 
        } else { 
            $lblRFStatus.Text = "GOOD"; $lblRFStatus.Foreground = "LightGreen" 
        }
        $window.FindName("lblRFCount").Text = "$rfCount failures"

        # Generate Recommendations
        Add-Recommendation "Enterprise Analysis Completed." "Info"
        
        if ($results.SystemEvents | Where {$_.Desc -match "Crash"}) { Add-Recommendation "CRITICAL: System Crashes detected. Check firmware/hardware." "Red" }
        if ($results.SystemEvents | Where {$_.Desc -match "HA Failover"}) { Add-Recommendation "WARNING: HA Failover event detected. Verify cluster sync." "Yellow" }
        
        if ($results.SwitchEvents | Where {$_.Desc -match "Offline"}) { Add-Recommendation "CRITICAL: Switches going offline. Check CAPWAP/Uplink." "Red" }
        if ($results.SwitchEvents | Where {$_.Desc -match "PoE"}) { Add-Recommendation "WARNING: Switch PoE errors detected. Check power budget." "Yellow" }
        
        if ($results.HardwareEvents | Where {$_.Desc -match "Fan|Temp"}) { Add-Recommendation "CRITICAL: Hardware environmental alarm (Fan/Temp)." "Red" }
        
        if ($results.SDWANEvents | Where {$_.Desc -match "SLA"}) { Add-Recommendation "WARNING: SD-WAN SLA Failures. Check ISP links." "Yellow" }

        if ($results.WirelessEvents | Where {$_.Desc -match "Reboot"}) { Add-Recommendation "CRITICAL: AP Reboots detected. Check PoE budget." "Red" }
        if ($rfCount -gt 20) { Add-Recommendation "WARNING: High RF interference/failures." "Yellow" }
        
        if ($results.SystemEvents.Count -eq 0 -and $results.SwitchEvents.Count -eq 0 -and $results.WirelessEvents.Count -eq 0) {
            Add-Recommendation "No critical infrastructure events found." "LightGreen"
        }

        # Raw Logs Preview
        $content = Get-Content $path -Raw
        if ($content.Length -gt 2000) { $content = $content.Substring(0, 2000) + "... (truncated)" }
        $txtRawLogs.Text = $content

        $lblStatus.Text = "Analysis Complete."

    } catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message, "Error")
        $lblStatus.Text = "Error."
    } finally {
        $progBar.Visibility = "Collapsed"
    }
})

function Update-DashboardCard($label, $events) {
    $count = $events.Count
    $critical = ($events | Where-Object {$_.Severity -eq "Critical"}).Count
    $warning = ($events | Where-Object {$_.Severity -eq "Warning"}).Count
    
    $labelName = $label.Name.Replace("Status", "Count")
    $countLabel = $window.FindName($labelName)
    $countLabel.Text = "$count events"

    if ($critical -gt 0) {
        $label.Text = "CRITICAL"
        $label.Foreground = "Red"
    } elseif ($warning -gt 0) {
        $label.Text = "WARNING"
        $label.Foreground = "Yellow"
    } elseif ($count -gt 0) {
        $label.Text = "INFO"
        $label.Foreground = "Cyan"
    } else {
        $label.Text = "HEALTHY"
        $label.Foreground = "LightGreen"
    }
}

function Add-Recommendation($text, $colorName) {
    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = "• $text"
    $block.FontSize = 14
    $block.Margin = "0,5,0,5"
    $block.TextWrapping = "Wrap"
    
    if ($colorName -eq "Red") { $block.Foreground = "#FF5555" }
    elseif ($colorName -eq "Yellow") { $block.Foreground = "#FFDD55" }
    elseif ($colorName -eq "LightGreen") { $block.Foreground = "#55FF55" }
    elseif ($colorName -eq "Cyan") { $block.Foreground = "#55FFFF" }
    else { $block.Foreground = "#DDDDDD" }
    
    $panelRecs.Children.Add($block)
}

$btnExport.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "Text Report (*.txt)|*.txt"
    $dlg.FileName = "Analysis_Report.txt"
    if ($dlg.ShowDialog() -eq $true) {
        $sb = New-Object System.Text.StringBuilder
        $sb.AppendLine("FORTIANALYZER ENTERPRISE REPORT") | Out-Null
        $sb.AppendLine("Date: $(Get-Date)") | Out-Null
        $sb.AppendLine("--------------------------------------------------") | Out-Null
        
        # Recommendations
        $sb.AppendLine("RECOMMENDATIONS:") | Out-Null
        foreach ($child in $panelRecs.Children) { $sb.AppendLine($child.Text) | Out-Null }
        
        # Events
        $sb.AppendLine("`nSYSTEM & HA EVENTS:") | Out-Null
        if ($lvSystem.ItemsSource) { $lvSystem.ItemsSource | ForEach { $sb.AppendLine("[$($_.Severity)] $($_.DateTime): $($_.Desc)") | Out-Null } }

        $sb.AppendLine("`nSWITCH EVENTS:") | Out-Null
        if ($lvSwitch.ItemsSource) { $lvSwitch.ItemsSource | ForEach { $sb.AppendLine("[$($_.Severity)] $($_.DateTime): $($_.Desc)") | Out-Null } }
        
        $sb.ToString() | Out-File $dlg.FileName
        [System.Windows.MessageBox]::Show("Report saved.", "Success")
    }
})

# Show Window
$window.ShowDialog() | Out-Null
