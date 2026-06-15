$resourceGroupName = "mate-azure-task-10"
$location = "canadacentral"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"

$sshKeyPublicKey = Get-Content "C:\Users\eldar\.ssh\id_ed25519.pub" -Raw

$vmUsername = "azureuser"

$vmNameBase = "matebox"
$vmImage = "Ubuntu2204"

$vmSize = "Standard_B2ats_v2"

function Create-SecurityRule([string]$Name, [int]$Priority, [int]$Port, [string]$Direction) {
    return New-AzNetworkSecurityRuleConfig -Name $Name `
        -Description "$Name access rule" `
        -Access Allow `
        -Protocol Tcp `
        -Direction $Direction `
        -Priority $Priority `
        -SourceAddressPrefix "*" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange "$Port"
}

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

$nsgRuleSSH = Create-SecurityRule -Name SSH -Priority 1001 -Port 22 -Direction Inbound
$nsgRuleHTTP = Create-SecurityRule -Name HTTP -Priority 1002 -Port 8080 -Direction Inbound

$nsg = New-AzNetworkSecurityGroup -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP -Force

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg
$vnet = New-AzVirtualNetwork -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnet -Force

$sshKey = New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

foreach ($i in 1..2) {
    New-AzVm `
        -ResourceGroupName $resourceGroupName `
        -Name "$vmNameBase$i" `
        -Location $location `
        -Image $vmImage `
        -Size $vmSize `
        -SubnetName $subnetName `
        -VirtualNetworkName $virtualNetworkName `
        -SecurityGroupName $networkSecurityGroupName `
        -SshKeyName $sshKeyName `
        -Zone "$i" `
        -Credential (Get-Credential -UserName $vmUsername)
}

$storageAccountName = "eldarstorage1"
$resourceGroupName  = "mate-azure-task-10"
$containerName      = "task-artifacts"

$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName

$ctx = $storageAccount.Context

New-AzStorageContainer `
  -Name $containerName `
  -Context $ctx `
  -Permission Off