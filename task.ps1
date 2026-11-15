$location = "denmarkeast" # any region that is available in your Azure subscription
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
if (-not (Get-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP -ErrorAction Stop
}

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
if (-not (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet -ErrorAction Stop
}

$sshKeyPath = "$HOME\.ssh\mate_azure_task2.pub"

if (-not (Get-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue)) {
    if (Test-Path $sshKeyPath) {
        $sshKeyPublicKey = (Get-Content $sshKeyPath -Raw).Trim()
        New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -Location $location -PublicKey $sshKeyPublicKey -ErrorAction Stop
    }
    else {
        New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -Location $location -ErrorAction Stop
    }
}
# Take a note that in this task VMs are deployed without public IPs and you won't be able
# to connect to them - that's on purpose! The "free" Public IP resource (Basic SKU,
# dynamic IP allocation) can't be deployed to the availability zone, and therefore can't 
# be attached to the VM. Don't trust me - test it yourself! 
# If you want to get a VM with public IP deployed to the availability zone - you need to use 
# Standard public IP SKU (which you will need to pay for, it is not included in the free account)
# and set same zone you would set on the VM, but this is not required in this task. 
# New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Basic -AllocationMethod Dynamic -DomainNameLabel "random32987"

$credential = Get-Credential -UserName "azureuser" -Message "Enter VM credentials"

$zones = @(1, 2)

foreach ($zone in $zones) {
    $name = "$vmName$zone"

    New-AzVM -ResourceGroupName $resourceGroupName -Name $name -Location $location -Image $vmImage -Size $vmSize -Credential $credential -SubnetName $subnetName -VirtualNetworkName $virtualNetworkName -SecurityGroupName $networkSecurityGroupName -SshKeyName $sshKeyName -Zone "$zone" -PublicIpAddressName "" -ErrorAction Stop
}

$results = @(
    Get-AzVM -ResourceGroupName $resourceGroupName |
        Select-Object Name, Location, Zones
)

ConvertTo-Json -InputObject $results | Set-Content "./result.json"
# -PublicIpAddressName $publicIpAddressName
