$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "C:\Users\ipppk\.ssh\id_rsa.pub" -Raw
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

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

# Створення першої віртуальної машини у зоні доступності 1
$vmName1 = "matebox1"
$zone1 = 1
$ipConfig1 = New-AzNetworkInterfaceIpConfig -Name "$vmName1-ipconfig" -SubnetId (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName).Subnets[0].Id
$nsg1 = Get-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName
$nic1 = New-AzNetworkInterface -Name "$vmName1-nic" -ResourceGroupName $resourceGroupName -Location $location -IpConfiguration $ipConfig1 -NetworkSecurityGroupId $nsg1.Id

$vmConfig1 = New-AzVmConfig -VMName $vmName1 -VMSize $vmSize
$vmConfig1 = Set-AzVMOperatingSystem -VM $vmConfig1 -Linux -ComputerName $vmName1 -Credential (New-Object PSCredential "azureuser", (ConvertTo-SecureString "placeholderpassword" -AsPlainText -Force)) -DisablePasswordAuthentication
$vmConfig1 = Set-AzVMSourceImage -VM $vmConfig1 -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"
$vmConfig1 = Add-AzVMNetworkInterface -VM $vmConfig1 -Id $nic1.Id
$vmConfig1 = Set-AzVMOSDisk -VM $vmConfig1 -CreateOption FromImage -Name "$vmName1-osdisk" -DiskSizeInGB 30

New-AzVm -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig1 -Zone $zone1 -SshKeyName $sshKeyName

# Створення другої віртуальної машини у зоні доступності 2
$vmName2 = "matebox2"
$zone2 = 2
$ipConfig2 = New-AzNetworkInterfaceIpConfig -Name "$vmName2-ipconfig" -SubnetId (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName).Subnets[0].Id
$nsg2 = Get-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName
$nic2 = New-AzNetworkInterface -Name "$vmName2-nic" -ResourceGroupName $resourceGroupName -Location $location -IpConfiguration $ipConfig2 -NetworkSecurityGroupId $nsg2.Id

$vmConfig2 = New-AzVmConfig -VMName $vmName2 -VMSize $vmSize
$vmConfig2 = Set-AzVMOperatingSystem -VM $vmConfig2 -Linux -ComputerName $vmName2 -Credential (New-Object PSCredential "azureuser", (ConvertTo-SecureString "placeholderpassword" -AsPlainText -Force)) -DisablePasswordAuthentication
$vmConfig2 = Set-AzVMSourceImage -VM $vmConfig2 -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"
$vmConfig2 = Add-AzVMNetworkInterface -VM $vmConfig2 -Id $nic2.Id
$vmConfig2 = Set-AzVMOSDisk -VM $vmConfig2 -CreateOption FromImage -Name "$vmName2-osdisk" -DiskSizeInGB 30

New-AzVm -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig2 -Zone $zone2 -SshKeyName $sshKeyName
