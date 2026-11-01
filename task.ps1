$location = "switzerlandnorth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B2ats_v2"

$localKeyPath = "$HOME\.ssh\matebox_task10_key"
if (-not (Test-Path "$localKeyPath.pub")) {
    Write-Host "Generating fresh SSH key..."
    ssh-keygen -t rsa -b 2048 -f $localKeyPath -N '""'
}
$sshKeyPublicKey = Get-Content "$localKeyPath.pub" -Raw

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP -Force

Write-Host "Creating Virtual Network and Subnet..."
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet -Force

Write-Host "Creating SSH Key Resource..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

$cred = New-Object System.Management.Automation.PSCredential ("azureuser", (ConvertTo-SecureString "IgnoreThisPassword123!" -AsPlainText -Force))

Write-Host "Creating VM 1 in Zone 1..."
New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name "$vmName-1" `
    -Location $location `
    -image $vmImage `
    -size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Credential $cred `
    -Zone 1

Write-Host "Creating VM 2 in Zone 2..."
New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name "$vmName-2" `
    -Location $location `
    -image $vmImage `
    -size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -Credential $cred `
    -Zone 2

Write-Host "=========================================="
Write-Host "Task 10 script completed successfully!"
Write-Host "=========================================="