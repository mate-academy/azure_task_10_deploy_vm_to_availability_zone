$ErrorActionPreference = "Stop"

$location = "denmarkeast"
$resourceGroupName = "mate-resources"

$networkSecurityGroupName = "defaultnsg"

$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "$HOME\.ssh\id_rsa.pub"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_B2s_v2"

$vmName1 = "matebox-zone1"
$vmName2 = "matebox-zone2"


# ============================================
# RESOURCE GROUP
# ============================================

Write-Host "Creating resource group $resourceGroupName ..."

New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location


# ============================================
# NETWORK SECURITY GROUP
# ============================================

Write-Host "Creating network security group $networkSecurityGroupName ..."

$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $networkSecurityGroupName


# ============================================
# VIRTUAL NETWORK
# ============================================

Write-Host "Creating virtual network $virtualNetworkName ..."

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix `
    -NetworkSecurityGroup $nsg

$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $virtualNetworkName `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnetConfig


# ============================================
# SSH KEY
# ============================================

Write-Host "Creating SSH key $sshKeyName ..."

$sshKey = New-AzSshKey `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $sshKeyName `
    -PublicKey $sshKeyPublicKey


# ============================================
# VM 1 - AVAILABILITY ZONE 1
# ============================================

Write-Host "Creating virtual machine $vmName1 in Availability Zone 1 ..."

$securePassword = ConvertTo-SecureString `
    "TempPassword123!" `
    -AsPlainText `
    -Force

$credential = New-Object `
    System.Management.Automation.PSCredential `
    ("azureuser", $securePassword)

New-AzVM `
    -Name $vmName1 `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Zone "1" `
    -Credential $credential `
    -VirtualNetworkName $virtualNetworkName `
    -SubnetName $subnetName `
    -SecurityGroupName $networkSecurityGroupName `
    -Image $vmImage `
    -Size $vmSize `
    -SshKeyName $sshKeyName


# ============================================
# VM 2 - AVAILABILITY ZONE 2
# ============================================

Write-Host "Creating virtual machine $vmName2 in Availability Zone 2 ..."

New-AzVM `
    -Name $vmName2 `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Zone "2" `
    -Credential $credential `
    -VirtualNetworkName $virtualNetworkName `
    -SubnetName $subnetName `
    -SecurityGroupName $networkSecurityGroupName `
    -Image $vmImage `
    -Size $vmSize `
    -SshKeyName $sshKeyName


# ============================================
# OUTPUT
# ============================================

Write-Host ""
Write-Host "========================================"
Write-Host "VM deployment completed!"
Write-Host "========================================"

Write-Host "Resource Group: $resourceGroupName"
Write-Host "Location:       $location"
Write-Host "VM 1:           $vmName1"
Write-Host "VM 1 Zone:      1"
Write-Host "VM 2:           $vmName2"
Write-Host "VM 2 Zone:      2"
Write-Host "VM Size:        $vmSize"
Write-Host "VM Image:       $vmImage"
Write-Host "========================================"