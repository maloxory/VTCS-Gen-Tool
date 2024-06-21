<#
    Title: VxRail TOR Configuration Script Generator (VTCS-Gen) v1.0
    Copyright© 2024 Magdy Aloxory. All rights reserved.
    Contact: maloxory@gmail.com
#>

# Check if the script is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch the script with administrator privileges
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Function to center text
function CenterText {
    param (
        [string]$text,
        [int]$width
    )
    
    $textLength = $text.Length
    $padding = ($width - $textLength) / 2
    return (" " * [math]::Max([math]::Ceiling($padding), 0)) + $text + (" " * [math]::Max([math]::Floor($padding), 0))
}

# Function to create a border
function CreateBorder {
    param (
        [string[]]$lines,
        [int]$width
    )

    $borderLine = "+" + ("-" * $width) + "+"
    $borderedText = @($borderLine)
    foreach ($line in $lines) {
        $borderedText += "|$(CenterText $line $width)|"
    }
    $borderedText += $borderLine
    return $borderedText -join "`n"
}

# Display script information with border
$title = "VxRail TOR Configuration Script Generator (VTCS-Gen) v1.0"
$copyright = "Copyright 2024 Magdy Aloxory. All rights reserved."
$contact = "Contact: maloxory@gmail.com"
$maxWidth = 60

$infoText = @($title, $copyright, $contact)
$borderedInfo = CreateBorder -lines $infoText -width $maxWidth

Write-Host $borderedInfo -ForegroundColor Cyan

# Function to generate the configuration script for a given TOR
function Generate-ConfigScript {
    param (
        [string]$hostname,
        [string]$mgmtIP,
        [string]$mgmtGateway,
        [string]$MGMT_VLAN_IP,
        [string]$vrrpVirtualIP,
        [string]$vltBackupIP,
        [hashtable]$vlanIDs,
        [string]$saveLocation
    )

    # Generate the configuration script content
    $configScript = @"
config
ip route 0.0.0.0/0 $mgmtGateway
no ipv6 mld snooping enable

configure terminal
hostname $hostname

interface mgmt1/1/1
no shutdown
no ip address dhcp
ip address $mgmtIP
management route 0.0.0.0/0 $mgmtGateway
ipv6 address autoconfig

interface vlan $($vlanIDs['MGMT-VLAN'])
description MGMT-VLAN
ip address $MGMT_VLAN_IP

vrrp-group 11
priority 150
virtual-address $vrrpVirtualIP
no shutdown
ipv6 mld snooping enable

interface vlan $($vlanIDs['oob'])
description oob
no shutdown

interface vlan $($vlanIDs['vSAN'])
description vSAN
no shutdown

interface vlan $($vlanIDs['vMotion'])
description vMotion
no shutdown

interface vlan $($vlanIDs['VM-Network1'])
description VM-Network1
no shutdown

interface vlan $($vlanIDs['VM-Network2'])
description VM-Network2
no shutdown

interface vlan $($vlanIDs['Internal_Mgmt'])
description Internal_Mgmt
no shutdown
ipv6 mld snooping querier

interface ethernet1/1/1
description "Appliance1 Port1"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/2
description "Appliance1 Port2"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/3
description "Appliance2 Port1"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/4
description "Appliance2 Port2"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/5
description "Appliance3 Port1"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/6
description "Appliance3 Port2"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/7
description "Appliance4 Port1"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/8
description "Appliance4 Port2"
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/49
 description VLTi
 no shutdown
 no switchport

interface ethernet1/1/50
 description VLTi
 no shutdown
 no switchport

interface ethernet1/1/51
 description VLTi
 no shutdown
 no switchport

interface ethernet1/1/52
 description VLTi
 no shutdown
 no switchport

interface ethernet1/1/55
description UP-Link-1
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

interface ethernet1/1/56
description UP-Link-2
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
flowcontrol receive on
flowcontrol transmit off
spanning-tree port type edge

vlt-domain 128
backup destination $vltBackupIP
discovery-interface ethernet1/1/49-1/1/52
peer-routing

interface port-channel 11
no shutdown
switchport mode trunk
switchport access vlan 1
switchport trunk allowed vlan $($vlanIDs.Values -join ',')
vlt-port-channel 11
spanning-tree disable

interface ethernet1/1/55
no shutdown
channel-group 11 mode active
no switchport

interface ethernet1/1/56
no shutdown
channel-group 11 mode active
no switchport

do write memory
"@

    # Define the file path
    $filePath = Join-Path -Path $saveLocation -ChildPath "${hostname}_DellSwitchConfig.txt"

    # Save the configuration script to a text file
    $configScript | Out-File -FilePath $filePath -Encoding UTF8

    # Success message
    Write-Host "Configuration script for $hostname has been generated successfully and saved to:" -ForegroundColor Green
    Write-Host (Resolve-Path $filePath) -ForegroundColor Cyan
}

# Main script
try {
    # Prompt for VLAN IDs and descriptions
    $vlanIDs = @{}
    $vlanDescriptions = @("MGMT-VLAN", "oob", "vSAN", "vMotion", "VM-Network1", "VM-Network2", "Internal_Mgmt")
    foreach ($vlan in $vlanDescriptions) {
        $vlanID = Read-Host "Enter the VLAN ID for $vlan"
        $vlanIDs[$vlan] = $vlanID
    }

    # Prompt for TOR-1 inputs
    Write-Host "Enter the details for TOR-1" -ForegroundColor Cyan
    $hostname1 = Read-Host "Enter the hostname for TOR-1"
    $mgmtIP1 = Read-Host "Enter the management IP address for TOR-1 with subnet (e.g., 172.16.91.101/24)"
    $mgmtGateway1 = Read-Host "Enter the management gateway for TOR-1 (e.g., 172.16.91.2)"
    $MGMT_VLAN_IP1 = Read-Host "Enter the IP address for MGMT VLAN for TOR-1 with subnet (e.g., 172.16.70.150/24)"
    $vrrpVirtualIP1 = Read-Host "Enter the VRRP virtual IP address for MGMT VLAN for TOR-1 (e.g., 172.16.70.152)"
    $vltBackupIP1 = Read-Host "Enter the VLT backup destination IP for TOR-1 (e.g., 172.16.70.151)"

    # Prompt for TOR-2 inputs
    Write-Host "Enter the details for TOR-2" -ForegroundColor Cyan
    $hostname2 = Read-Host "Enter the hostname for TOR-2"
    $mgmtIP2 = Read-Host "Enter the management IP address for TOR-2 with subnet (e.g., 172.16.91.102/24)"
    $mgmtGateway2 = Read-Host "Enter the management gateway for TOR-2 (e.g., 172.16.91.2)"
    $MGMT_VLAN_IP2 = Read-Host "Enter the IP address for MGMT VLAN for TOR-2 with subnet (e.g., 172.16.70.151/24)"
    $vrrpVirtualIP2 = Read-Host "Enter the VRRP virtual IP address for MGMT VLAN for TOR-2 (e.g., 172.16.70.153)"
    $vltBackupIP2 = Read-Host "Enter the VLT backup destination IP for TOR-2 (e.g., 172.16.70.152)"

    # Prompt for save location
    $saveLocation = Read-Host "Enter the path where you want to save the configuration files (`$env:USERPROFILE\Desktop` for desktop)"

    if (-not $saveLocation) {
        $saveLocation = "$env:USERPROFILE\Desktop"
    }

    # Generate config scripts for TOR-1 and TOR-2
    Generate-ConfigScript -hostname $hostname1 -mgmtIP $mgmtIP1 -mgmtGateway $mgmtGateway1 -MGMT_VLAN_IP $MGMT_VLAN_IP1 -vrrpVirtualIP $vrrpVirtualIP1 -vltBackupIP $vltBackupIP1 -vlanIDs $vlanIDs -saveLocation $saveLocation
    Generate-ConfigScript -hostname $hostname2 -mgmtIP $mgmtIP2 -mgmtGateway $mgmtGateway2 -MGMT_VLAN_IP $MGMT_VLAN_IP2 -vrrpVirtualIP $vrrpVirtualIP2 -vltBackupIP $vltBackupIP2 -vlanIDs $vlanIDs -saveLocation $saveLocation

    # Success message with file paths
    Write-Host "Configuration scripts have been generated successfully and saved to:" -ForegroundColor Green
    Write-Host (Resolve-Path (Join-Path -Path $saveLocation -ChildPath "${hostname1}_DellSwitchConfig.txt")) -ForegroundColor Cyan
    Write-Host (Resolve-Path (Join-Path -Path $saveLocation -ChildPath "${hostname2}_DellSwitchConfig.txt")) -ForegroundColor Cyan
} catch {
    # Error message
    Write-Host "Failed to generate the configuration script." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

pause