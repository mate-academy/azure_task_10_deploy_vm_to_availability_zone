$firstVMname = "firstVM"
$secondVMname = "secondVM"

$location = "koreacentral"
$resourceGroupName = "mate-azure-task-10"

$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"

$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "$HOME\.ssh\id_rsa.pub"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_D2s_v3"

# Linux credentials
$cred = Get-Credential

Write-Host "Creating resource group..."
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location

Write-Host "Creating network security group..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22 `
    -Access Allow

New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH

Write-Host "Creating virtual network..."
$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnet

Write-Host "Creating SSH key resource..."
New-AzSshKey `
    -Name $sshKeyName `
    -ResourceGroupName $resourceGroupName `
    -PublicKey $sshKeyPublicKey

Write-Host "Creating first VM in Zone 1..."
New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $firstVMname `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -Credential $cred `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Zone 1

Write-Host "Creating second VM in Zone 2..."
New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $secondVMname `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -Credential $cred `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Zone 2