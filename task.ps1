$location = "BrazilSouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

# New-AzVM (Simple parameter set) requires a PSCredential:
# - username/password are used only for provisioning the OS account
# - you won't SSH with password if you use SSH keys, but Azure still needs the username
$adminUsername = "azureuser"
$adminPassword = ConvertTo-SecureString "P@ssw0rd-ChangeMe-123!" -AsPlainText -Force
$adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH  = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22   -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name "$vmName-1" `
  -Location $location `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName `
  -Credential $adminCredential `
  -Zone "1"

New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name "$vmName-2" `
  -Location $location `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName `
  -Credential $adminCredential `
  -Zone "2"
