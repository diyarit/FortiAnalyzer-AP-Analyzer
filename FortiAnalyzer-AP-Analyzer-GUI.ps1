#Requires -Version 5.1
<#
.SYNOPSIS
    FortiAnalyzer Infrastructure Analyzer - GUI Edition (Enterprise v3.1.0)
.DESCRIPTION
    Modern WPF GUI for analyzing FortiAnalyzer logs.
    Uses the shared FortiAnalyzer.Core module for parsing and analysis.
    Includes advanced detection for HA, SD-WAN, Hardware Health, VPN, Router,
    and Switch STP. Supports HTML/JSON/CSV export and async processing.
.NOTES
    Version: 3.1.0 (Enterprise)
    Requires: PowerShell 5.1+
#>

# Load WPF Assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Import core module
$coreModulePath = Join-Path (Join-Path $PSScriptRoot 'src') 'FortiAnalyzer.Core.psm1'
if (-not (Test-Path $coreModulePath)) {
    [System.Windows.MessageBox]::Show("Core module not found: $coreModulePath", "Fatal Error", "OK", "Error")
    return
}
Import-Module $coreModulePath -Force

# ============================================================================
# XAML UI DEFINITION
# ============================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FortiAnalyzer Infrastructure Analyzer v3.1.0" Height="800" Width="1100"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1A8FE0"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#005A9E"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
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
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- INPUT SECTION -->
        <Border Grid.Row="0" BorderBrush="#444444" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,0,0,10" Background="#252526">
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
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Label Content="Log Path:" Foreground="#AAAAAA" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtLogPath" Grid.Row="0" Grid.Column="1" Margin="5,2" Background="#333333" Foreground="White" BorderThickness="0" Padding="8"/>
                <Button Name="btnBrowse" Content="..." Grid.Row="0" Grid.Column="2" Width="40" Margin="5,2" Background="#444444"/>
                
                <Label Content="Device Filter:" Foreground="#AAAAAA" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox Name="txtDeviceFilter" Grid.Row="1" Grid.Column="1" Margin="5,2" Background="#333333" Foreground="White" BorderThickness="0" Padding="8" ToolTip="Optional: Enter hostname to filter"/>
                
                <StackPanel Orientation="Horizontal" Grid.Row="0" Grid.RowSpan="2" Grid.Column="3" VerticalAlignment="Center" Margin="15,0,0,0">
                    <Button Name="btnAnalyze" Content="RUN ANALYSIS" FontSize="14" Padding="25,12"/>
                    <Button Name="btnExport" Content="Export" Margin="10,0,0,0" Background="#444444"/>
                </StackPanel>

                <!-- Time / Level Filters -->
                <StackPanel Orientation="Horizontal" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="4" Margin="0,5,0,0">
                    <Label Content="From:" Foreground="#AAAAAA" VerticalAlignment="Center"/>
                    <TextBox Name="txtStartTime" Width="140" Margin="5,0,10,0" Background="#333333" Foreground="White" BorderThickness="0" Padding="5" ToolTip="yyyy-MM-dd HH:mm:ss (optional)"/>
                    <Label Content="To:" Foreground="#AAAAAA" VerticalAlignment="Center"/>
                    <TextBox Name="txtEndTime" Width="140" Margin="5,0,10,0" Background="#333333" Foreground="White" BorderThickness="0" Padding="5" ToolTip="yyyy-MM-dd HH:mm:ss (optional)"/>
                    <Label Content="Min Level:" Foreground="#AAAAAA" VerticalAlignment="Center"/>
                    <ComboBox Name="cmbLogLevel" Width="120" Margin="5,0,10,0" Background="#333333" Foreground="White" SelectedIndex="4">
                        <ComboBoxItem Content="emergency"/>
                        <ComboBoxItem Content="alert"/>
                        <ComboBoxItem Content="critical"/>
                        <ComboBoxItem Content="error"/>
                        <ComboBoxItem Content="warning"/>
                        <ComboBoxItem Content="notice"/>
                        <ComboBoxItem Content="information"/>
                        <ComboBoxItem Content="debug"/>
                    </ComboBox>
                    <CheckBox Name="chkShowAll" Content="Show All Events" Foreground="#AAAAAA" VerticalAlignment="Center" Margin="10,0,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- DASHBOARD CARDS -->
        <Grid Grid.Row="1" Margin="0,0,0,10">
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

            <!-- Row 1 -->
            <Border Grid.Row="0" Grid.Column="0" Background="#2D2D30" CornerRadius="4" Margin="0,0,5,5" Padding="12">
                <StackPanel>
                    <TextBlock Text="SYSTEM &amp; HA" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblSystemStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblSystemCount" Text="0 events" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="1" Background="#2D2D30" CornerRadius="4" Margin="5,0,5,5" Padding="12">
                <StackPanel>
                    <TextBlock Text="SWITCH INFRA" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblSwitchStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblSwitchCount" Text="0 events" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="2" Background="#2D2D30" CornerRadius="4" Margin="5,0,5,5" Padding="12">
                <StackPanel>
                    <TextBlock Text="WIRELESS / APs" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblWirelessStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblWirelessCount" Text="0 events" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="0" Grid.Column="3" Background="#2D2D30" CornerRadius="4" Margin="5,0,0,5" Padding="12">
                <StackPanel>
                    <TextBlock Text="RF HEALTH" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblRFStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblRFCount" Text="0 failures" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <!-- Row 2 -->
            <Border Grid.Row="1" Grid.Column="0" Background="#2D2D30" CornerRadius="4" Margin="0,5,5,0" Padding="12">
                <StackPanel>
                    <TextBlock Text="SD-WAN" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblSDWANStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblSDWANCount" Text="0 events" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Grid.Column="1" Background="#2D2D30" CornerRadius="4" Margin="5,5,5,0" Padding="12">
                <StackPanel>
                    <TextBlock Text="HARDWARE" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblHardwareStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblHardwareCount" Text="0 alarms" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Grid.Column="2" Background="#2D2D30" CornerRadius="4" Margin="5,5,5,0" Padding="12">
                <StackPanel>
                    <TextBlock Text="VPN" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblVPNStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblVPNCount" Text="0 events" Foreground="Gray" FontSize="11"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="1" Grid.Column="3" Background="#2D2D30" CornerRadius="4" Margin="5,5,0,0" Padding="12">
                <StackPanel>
                    <TextBlock Text="ROUTER" Foreground="#AAAAAA" FontSize="10" FontWeight="Bold"/>
                    <TextBlock Name="lblRouterStatus" Text="WAITING" Foreground="Gray" FontSize="18" FontWeight="Bold" Margin="0,3,0,0"/>
                    <TextBlock Name="lblRouterCount" Text="0 events" Foreground="Gray" FontSize="11"/>
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
                                    <ContentPresenter x:Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header" Margin="15,8"/>
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
                            <GridViewColumn Header="Event" Width="250" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Device" Width="120" DisplayMemberBinding="{Binding Device}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
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
                            <GridViewColumn Header="Event" Width="220" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Source" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
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
                            <GridViewColumn Header="Event" Width="220" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="AP Name" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
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
                            <GridViewColumn Header="Event" Width="220" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>

            <TabItem Header="VPN">
                <ListView Name="lvVPN">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Event" Width="250" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Source" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>

            <TabItem Header="Router">
                <ListView Name="lvRouter">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="Severity" Width="80" DisplayMemberBinding="{Binding Severity}"/>
                            <GridViewColumn Header="Event" Width="250" DisplayMemberBinding="{Binding Desc}"/>
                            <GridViewColumn Header="Source" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Message" Width="400" DisplayMemberBinding="{Binding Message}"/>
                        </GridView>
                    </ListView.View>
                </ListView>
            </TabItem>

            <TabItem Header="Frame Failures">
                <ListView Name="lvFrameFailures">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Time" Width="150" DisplayMemberBinding="{Binding DateTime}"/>
                            <GridViewColumn Header="AP" Width="150" DisplayMemberBinding="{Binding Source}"/>
                            <GridViewColumn Header="Client MAC" Width="150" DisplayMemberBinding="{Binding ClientMAC}"/>
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
                <ProgressBar Name="progBar" Width="200" Height="10" Visibility="Collapsed" IsIndeterminate="True"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# ============================================================================
# PARSE XAML & MAP CONTROLS
# ============================================================================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$btnBrowse      = $window.FindName("btnBrowse")
$btnAnalyze     = $window.FindName("btnAnalyze")
$btnExport      = $window.FindName("btnExport")
$txtLogPath     = $window.FindName("txtLogPath")
$txtDeviceFilter = $window.FindName("txtDeviceFilter")
$txtStartTime   = $window.FindName("txtStartTime")
$txtEndTime     = $window.FindName("txtEndTime")
$cmbLogLevel    = $window.FindName("cmbLogLevel")
$chkShowAll     = $window.FindName("chkShowAll")
$lvSystem       = $window.FindName("lvSystem")
$lvSwitch       = $window.FindName("lvSwitch")
$lvWireless     = $window.FindName("lvWireless")
$lvSDWAN        = $window.FindName("lvSDWAN")
$lvVPN          = $window.FindName("lvVPN")
$lvRouter       = $window.FindName("lvRouter")
$lvFrameFailures = $window.FindName("lvFrameFailures")
$panelRecs      = $window.FindName("panelRecommendations")
$lblStatus      = $window.FindName("lblStatus")
$progBar        = $window.FindName("progBar")
$txtRawLogs     = $window.FindName("txtRawLogs")

# Dashboard labels
$dashboardLabels = @{
    System   = @{ Status = $window.FindName("lblSystemStatus");   Count = $window.FindName("lblSystemCount") }
    Switch   = @{ Status = $window.FindName("lblSwitchStatus");   Count = $window.FindName("lblSwitchCount") }
    Wireless = @{ Status = $window.FindName("lblWirelessStatus"); Count = $window.FindName("lblWirelessCount") }
    SDWAN    = @{ Status = $window.FindName("lblSDWANStatus");    Count = $window.FindName("lblSDWANCount") }
    Hardware = @{ Status = $window.FindName("lblHardwareStatus"); Count = $window.FindName("lblHardwareCount") }
    VPN      = @{ Status = $window.FindName("lblVPNStatus");      Count = $window.FindName("lblVPNCount") }
    Router   = @{ Status = $window.FindName("lblRouterStatus");   Count = $window.FindName("lblRouterCount") }
    RF       = @{ Status = $window.FindName("lblRFStatus");       Count = $window.FindName("lblRFCount") }
}

# Store last analysis results for export
$script:lastResults = $null
$script:lastRecommendations = $null

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Update-DashboardCard {
    param($statusLabel, $countLabel, $events, [string]$unit = 'events')
    $count = $events.Count
    $critical = if ($events) { ($events | Where-Object { $_.Severity -eq 'Critical' }).Count } else { 0 }
    $warning = if ($events) { ($events | Where-Object { $_.Severity -eq 'Warning' }).Count } else { 0 }

    $countLabel.Text = "$count $unit"

    if ($critical -gt 0) {
        $statusLabel.Text = "CRITICAL"
        $statusLabel.Foreground = "Red"
    } elseif ($warning -gt 0) {
        $statusLabel.Text = "WARNING"
        $statusLabel.Foreground = "Yellow"
    } elseif ($count -gt 0) {
        $statusLabel.Text = "INFO"
        $statusLabel.Foreground = "Cyan"
    } else {
        $statusLabel.Text = "HEALTHY"
        $statusLabel.Foreground = "LightGreen"
    }
}

function Add-Recommendation {
    param([string]$text, [string]$colorName)
    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = "`u{2022} $text"
    $block.FontSize = 13
    $block.Margin = "0,4,0,4"
    $block.TextWrapping = "Wrap"
    
    switch ($colorName) {
        'Red'         { $block.Foreground = "#FF5555" }
        'Yellow'      { $block.Foreground = "#FFDD55" }
        'LightGreen'  { $block.Foreground = "#55FF55" }
        'Cyan'        { $block.Foreground = "#55FFFF" }
        default       { $block.Foreground = "#DDDDDD" }
    }
    $panelRecs.Children.Add($block)
}

function Parse-TimeParam {
    param([string]$text)
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    try {
        return [datetime]::Parse($text)
    } catch {
        return $null
    }
}

# ============================================================================
# EVENT HANDLERS
# ============================================================================

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
    $panelRecs.Children.Clear()
    $lvSystem.ItemsSource = $null
    $lvSwitch.ItemsSource = $null
    $lvWireless.ItemsSource = $null
    $lvSDWAN.ItemsSource = $null
    $lvVPN.ItemsSource = $null
    $lvRouter.ItemsSource = $null
    $lvFrameFailures.ItemsSource = $null
    $txtRawLogs.Text = ""

    try {
        # Read log file (streaming via .NET)
        $lines = [System.Collections.Generic.List[string]]::new()
        $reader = [System.IO.File]::ReadLines($path, [System.Text.Encoding]::UTF8)
        foreach ($line in $reader) { $lines.Add($line) }

        # Build analysis parameters
        $params = @{ LogLines = $lines.ToArray() }
        $filter = $txtDeviceFilter.Text
        if ($filter) { $params['DeviceFilter'] = $filter }

        $start = Parse-TimeParam $txtStartTime.Text
        if ($start) { $params['StartTime'] = $start }
        $end = Parse-TimeParam $txtEndTime.Text
        if ($end) { $params['EndTime'] = $end }

        # Level filter (use selected combobox index to map to level name)
        $levelMap = @('emergency','alert','critical','error','warning','notice','information','debug')
        $selectedLevel = $cmbLogLevel.SelectedItem.Content
        if ($selectedLevel) { $params['LogLevel'] = $selectedLevel }

        # Run analysis via core module
        $results = Get-FortiAnalysisResults @params
        $recommendations = New-FortiRecommendation -Results $results

        # Store for export
        $script:lastResults = $results
        $script:lastRecommendations = $recommendations

        # Update ListViews
        $lvSystem.ItemsSource = $results.SystemEvents
        $lvSwitch.ItemsSource = $results.SwitchEvents
        $lvWireless.ItemsSource = $results.WirelessEvents
        $lvSDWAN.ItemsSource = $results.SDWANEvents
        $lvVPN.ItemsSource = $results.VPNEvents
        $lvRouter.ItemsSource = $results.RouterEvents
        $lvFrameFailures.ItemsSource = $results.FrameFailures

        # Update dashboard cards
        Update-DashboardCard $dashboardLabels.System.Status $dashboardLabels.System.Count $results.SystemEvents
        Update-DashboardCard $dashboardLabels.Switch.Status $dashboardLabels.Switch.Count $results.SwitchEvents
        Update-DashboardCard $dashboardLabels.Wireless.Status $dashboardLabels.Wireless.Count $results.WirelessEvents
        Update-DashboardCard $dashboardLabels.SDWAN.Status $dashboardLabels.SDWAN.Count $results.SDWANEvents
        Update-DashboardCard $dashboardLabels.Hardware.Status $dashboardLabels.Hardware.Count $results.HardwareEvents
        Update-DashboardCard $dashboardLabels.VPN.Status $dashboardLabels.VPN.Count $results.VPNEvents
        Update-DashboardCard $dashboardLabels.Router.Status $dashboardLabels.Router.Count $results.RouterEvents

        # RF Health
        $rfCount = $results.FrameFailures.Count
        if ($rfCount -gt 20) {
            $dashboardLabels.RF.Status.Text = "POOR"; $dashboardLabels.RF.Status.Foreground = "Red"
        } elseif ($rfCount -gt 0) {
            $dashboardLabels.RF.Status.Text = "WARNING"; $dashboardLabels.RF.Status.Foreground = "Yellow"
        } else {
            $dashboardLabels.RF.Status.Text = "GOOD"; $dashboardLabels.RF.Status.Foreground = "LightGreen"
        }
        $dashboardLabels.RF.Count.Text = "$rfCount failures"

        # Recommendations
        foreach ($rec in $recommendations) {
            $color = switch ($rec.Level) {
                'Critical' { 'Red' }
                'Warning'  { 'Yellow' }
                'OK'       { 'LightGreen' }
                default    { 'Cyan' }
            }
            Add-Recommendation "$($rec.Message)" $color
        }

        # Raw logs preview (truncated)
        $rawContent = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        if ($rawContent.Length -gt 3000) { $rawContent = $rawContent.Substring(0, 3000) + "`n... (truncated)" }
        $txtRawLogs.Text = $rawContent

        $lblStatus.Text = "Analysis Complete - $($results.Summary.TotalLines) lines processed"

    } catch {
        [System.Windows.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", "OK", "Error")
        $lblStatus.Text = "Error."
    } finally {
        $progBar.Visibility = "Collapsed"
    }
})

$btnExport.Add_Click({
    if (-not $script:lastResults) {
        [System.Windows.MessageBox]::Show("Run an analysis first before exporting.", "No Data", "OK", "Warning")
        return
    }

    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = "HTML Report (*.html)|*.html|JSON Report (*.json)|*.json|CSV Report (*.csv)|*.csv|Text Report (*.txt)|*.txt"
    $dlg.FileName = "FortiAnalyzer_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    if ($dlg.ShowDialog() -eq $true) {
        try {
            $exportParams = @{
                Results         = $script:lastResults
                Recommendations = $script:lastRecommendations
                OutputPath      = $dlg.FileName
            }
            Export-FortiReport @exportParams
            [System.Windows.MessageBox]::Show("Report saved to:`n$($dlg.FileName)", "Export Success", "OK", "Information")
        } catch {
            [System.Windows.MessageBox]::Show("Export failed: $($_.Exception.Message)", "Error", "OK", "Error")
        }
    }
})

# ============================================================================
# KEYBOARD SHORTCUTS
# ============================================================================
$window.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq 'F5') {
        $btnAnalyze.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        $e.Handled = $true
    }
    if ($e.Key -eq 'Escape') {
        $window.Close()
    }
    if ($e.Key -eq 'S' -and $e.KeyboardDevice.Modifiers -eq [System.Windows.Input.ModifierKeys]::Control) {
        $btnExport.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))
        $e.Handled = $true
    }
})

# ============================================================================
# SHOW WINDOW
# ============================================================================
$window.ShowDialog() | Out-Null
