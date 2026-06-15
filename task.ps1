$location = "uksouth"
$resourceGroupName = "mate-resources"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$sshKeyName = "linuxboxsshkey"
$vm1Name = "matebox1"
$vm2Name = "matebox2"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vm1Name `
  -Location $location `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName `
  -Zone 1 `
  -PublicIpAddressName ""

New-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vm2Name `
  -Location $location `
  -Image $vmImage `
  -Size $vmSize `
  -SubnetName $subnetName `
  -VirtualNetworkName $virtualNetworkName `
  -SecurityGroupName $networkSecurityGroupName `
  -SshKeyName $sshKeyName `
  -Zone 2 `
  -PublicIpAddressName ""
