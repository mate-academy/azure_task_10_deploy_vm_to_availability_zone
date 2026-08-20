$location = "polandcentral"
$resourceGroupName = "mate-azure-task-10"

$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"

$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub"

$vmName1 = "matebox1"
$vmName2 = "matebox2"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_B2s_v2"

# Credentials for both VMs
Write-Host "Enter credentials for the Linux VMs..."
$credential = Get-Credential

Write-Host "Creating resource group $resourceGroupName ..."

New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location

Write-Host "Creating network security group $networkSecurityGroupName ..."

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22 `
    -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 8080 `
    -Access Allow

New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Creating virtual network $virtualNetworkName ..."

$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnet

Write-Host "Creating SSH key $sshKeyName ..."

New-AzSshKey `
    -Name $sshKeyName `
    -ResourceGroupName $resourceGroupName `
    -PublicKey $sshKeyPublicKey

Write-Host "Creating VM $vmName1 in Availability Zone 1 ..."

New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName1 `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Credential $credential `
    -Zone "1"

Write-Host "Creating VM $vmName2 in Availability Zone 2 ..."

New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName2 `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Credential $credential `
    -Zone "2"

Write-Host "Deployment completed."
