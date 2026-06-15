$resourceGroupName = "mate-task-10-sweden"
$location = "swedencentral"
$vmName1 = "matebox-zone1"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B2ats_v2"
$virtualNetworkName = "vnet"
$subnetName = "default"
$networkSecurityGroupName = "defaultnsg"
$sshKeyName = "linuxboxsshkey"

Write-Host "Retrying VM 1 in Zone 3..." -ForegroundColor Yellow
New-AzVM -ResourceGroupName $resourceGroupName `
    -Name $vmName1 `
    -Location $location `
    -VirtualNetworkName $virtualNetworkName `
    -SubnetName $subnetName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -PublicIpAddressName $null `
    -Image $vmImage `
    -Size $vmSize `
    -Zone "3" `
    -OpenPorts 22