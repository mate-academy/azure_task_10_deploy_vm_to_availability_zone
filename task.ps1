# Define the parameters
$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "C:\Users\shche\.ssh\id_ed25519.pub"
$vm1Name = "matebox1"
$vm2Name = "matebox2"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$zone1 = "1"
$zone2 = "2"

# Create a resource group
Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a network security group with rules
Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

# Create a virtual network and subnet
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
Write-Host "Creating a virtual network $virtualNetworkName ..."
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

# Create an SSH key
Write-Host "Creating an SSH key $sshKeyName ..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

# Create VM1 in Availability Zone 1
Write-Host "Creating VM $vm1Name in availability zone $zone1 ..."
New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vm1Name `
  -Location $location `
  -Zone $zone1 `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName

# Create VM2 in Availability Zone 2
Write-Host "Creating VM $vm2Name in availability zone $zone2 ..."
New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vm2Name `
  -Location $location `
  -Zone $zone2 `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName
