$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$sshKeyName = "linuxboxsshkey"
$vmName1 = "matebox1"
$vmName2 = "matebox2"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

Write-Host "Creating VM 1 in zone 1 ..."
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vmName1 `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone "1"

Write-Host "Creating VM 2 in zone 2 ..."
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vmName2 `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone "2"
