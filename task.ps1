$location = "uksouth"
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
$vm_count = 2

if (-Not(Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)){
  Write-Host "Creating Resource Group: $resourceGroupName in $location" -ForegroundColor Green
  $resourceGroupName = New-AzResourceGroup -Name $resourceGroupName -Location $location

  if ($resourceGroupName -ne $null) {
    Write-Host "Resource Group $resourceGroupName created succesfully" -ForegroundColor Green
  }
  else {
    Write-Host "Failde to create Resource Group $resourceGroupName." -ForegroundColor Red
    exit
  }
}
else {
  Write-Host "Resource Group $resourceGroupNane already exist" -ForegroundColor Yellow
}

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

for ($i = 1; ($i -le $vm_count); $i++) {
  $vmNameMate = $vmName + $i + "vm"
  $VMStatus = Get-AzVM -Name $vmNameMate -EA 0 -WA 0
  if(!$VMStatus) {
    New-AzVm `
      -ResourceGroupName $resourceGroupName `
      -Zone $i `
      -Name $vmNameMate `
      -Location $location `
      -image $vmImage `
      -size $vmSize `
      -SubnetName $subnetName `
      -VirtualNetworkName $virtualNetworkName `
      -SecurityGroupName $networkSecurityGroupName `
      -SshKeyName $sshKeyName
      # -PublicIpAddressName $publicIpAddressName
  }
}


