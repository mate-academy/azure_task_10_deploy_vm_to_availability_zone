$location = "southafricanorth"
$resourceGroupName = "mate-resources"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"

# Перевірка та автоматичне створення SSH-ключа за потреби
$sshKeyPath = "$HOME/.ssh/id_rsa.pub"
if (-not (Test-Path $sshKeyPath)) {
    if (Test-Path "$HOME/.ssh/id_ed25519.pub") {
        $sshKeyPath = "$HOME/.ssh/id_ed25519.pub"
    } else {
        Write-Host "Створення нового SSH-ключа $sshKeyPath ..."
        New-Item -ItemType Directory -Path "$HOME/.ssh" -Force | Out-Null
        ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N '""'
    }
}
$sshKeyPublicKey = Get-Content $sshKeyPath -Raw

$vmName = "matebox"
$vmImage = "Ubuntu2204"
#$vmSize = "Standard_B2as_v2"
$vmSize = "Standard_B1s"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Creating virtual network $virtualNetworkName and subnet $subnetName ..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig

Write-Host "Creating SSH Key resource $sshKeyName ..."
New-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -PublicKey $sshKeyPublicKey -Location $location

$secPassword = ConvertTo-SecureString "P@ssw0rd123456!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $secPassword)

# Розгортання двох ВМ у двох окремих зонах доступності
$zones = @("1", "2")

foreach ($zone in $zones) {
    Write-Host "Creating Virtual Machine ${vmName}-${zone} in Availability Zone $zone ..."
    New-AzVm `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name "${vmName}-${zone}" `
        -Size $vmSize `
        -Image $vmImage `
        -Credential $cred `
        -VirtualNetworkName $virtualNetworkName `
        -SubnetName $subnetName `
        -SecurityGroupName $networkSecurityGroupName `
        -SshKeyName $sshKeyName `
        -Zone $zone
}
