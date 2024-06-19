$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "C:\Users\admin\.ssh\id_rsa.pub"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

$vmZone_1 = 1
$vmZone_2 = 2


Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

# Take a note that in this task VMs are deployed without public IPs and you won't be able
# to connect to them - that's on purpose! The "free" Public IP resource (Basic SKU,
# dynamic IP allocation) can't be deployed to the availability zone, and therefore can't 
# be attached to the VM. Don't trust me - test it yourself! 
# If you want to get a VM with public IP deployed to the availability zone - you need to use 
# Standard public IP SKU (which you will need to pay for, it is not included in the free account)
# and set same zone you would set on the VM, but this is not required in this task. 
# New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Basic -AllocationMethod Dynamic -DomainNameLabel "random32987"

Write-Host "Creating the first VM to the zone $vmZone_1"
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name "${vmName}-1" `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone $vmZone_1
Write-Host "The first VM in the zone $vmZone_1 has created"

Write-Host "Creating the second VM to the zone $vmZone_2"
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name "${vmName}-2" `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone $vmZone_2
Write-Host "The second VM in the zone $vmZone_2 has created"