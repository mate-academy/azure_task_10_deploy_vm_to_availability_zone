$location = "swedencentral"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$sshKeyName = "linuxboxsshkey"
$vmSize = "Standard_D2as_v5"
$vmImage = "Ubuntu2204"

# 1. Створення групи ресурсів
if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# 2. Створення мережевої інфраструктури (NSG + VNet)
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsg = New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH

$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg
$vnet = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnetConfig

# 3. ГЕНЕРУЄМО КЛЮЧ ОКРЕМО (якщо його ще немає)
$existingKey = Get-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -ErrorAction SilentlyContinue
if ($null -eq $existingKey) {
  Write-Host "Генерація SSH ключа $sshKeyName..." -ForegroundColor Yellow
  New-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -Location $location
}

# 4. Цикл розгортання
for ($i = 1; $i -le 2; $i++) {
  Write-Host "--- Розгортання matebox$i у Зоні $i ---" -ForegroundColor Cyan
    
  # Використовуємо Splatting для чіткості
  $vmParams = @{
    ResourceGroupName  = $resourceGroupName
    Name               = "matebox$i"
    Location           = $location
    Image              = $vmImage
    Size               = $vmSize
    VirtualNetworkName = $virtualNetworkName
    SubnetName         = $subnetName
    SecurityGroupName  = $networkSecurityGroupName
    SshKeyName         = $sshKeyName
    Zone               = $i
  }

  New-AzVm @vmParams -Verbose
}