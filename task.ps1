# Script to deploy 2 VMs across 2 availability zones with SSH key resource

$location          = "italynorth"
$resourceGroupName = "mate-azure-task-10"

$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName       = "vnet"
$subnetName               = "default"

$sshKeyName = "linuxboxsshkey"

$vmSize = "Standard_B1s"
$vmImage = "Ubuntu2204"

Write-Host "Creating a resource group $resourceGroupName in $location ..."
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location `
    -Force | Out-Null

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsg = New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location

Write-Host "Creating a virtual network $virtualNetworkName and subnet $subnetName ..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix "10.0.0.0/24" `
    -NetworkSecurityGroup $nsg

$vnet = New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnetConfig

Write-Host "Creating SSH public key resource $sshKeyName ..."
$sshPublicKey = Get-Content -Path "$HOME/.ssh/id_rsa.pub" -Raw

New-AzSshKey `
    -Name $sshKeyName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -PublicKey $sshPublicKey | Out-Null

$commonVmParams = @{
    ResourceGroupName  = $resourceGroupName
    Location           = $location
    Image              = $vmImage
    Size               = $vmSize
    VirtualNetworkName = $virtualNetworkName
    SubnetName         = $subnetName
    SecurityGroupName  = $networkSecurityGroupName
    SshKeyName         = $sshKeyName
}

Write-Host "Creating VM matebox-1 in Availability Zone 1 ..."
New-AzVm @commonVmParams `
    -Name "matebox-1" `
    -Zone 1

Write-Host "Creating VM matebox-2 in Availability Zone 2 ..."
New-AzVm @commonVmParams `
    -Name "matebox-2" `
    -Zone 2

Write-Host "Deployment complete!"
