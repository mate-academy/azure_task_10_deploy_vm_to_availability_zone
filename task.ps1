# task.ps1
$ErrorActionPreference = "Stop"
$ConfirmPreference = "None"
$ProgressPreference = "SilentlyContinue"

$location = "polandcentral"
$resourceGroupName = "mate-azure-task-10"

$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = (Get-Content -Raw "/root/.ssh/mate_azure_vm.pub").Trim()

$vmNames = @("matebox-z1", "matebox-z2")
$vmZones = @("1", "2")
$vmSize = "Standard_B1s"
$vmImage = "Ubuntu2204"   # <-- ВАЖНО: friendly name

# admin-учетка нужна для создания VM (даже если вход по SSH-ключу)
$adminUsername = "azureuser"
$plainPassword = "P@ss" + (Get-Random -Minimum 10000000 -Maximum 99999999) + "aA!"
$adminPassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

function Invoke-WithRetry {
  param(
    [Parameter(Mandatory=$true)][ScriptBlock]$Script,
    [int]$Attempts = 4,
    [int]$DelaySeconds = 12
  )
  for ($a=1; $a -le $Attempts; $a++) {
    try { return & $Script }
    catch {
      Write-Host "Attempt $a/$Attempts failed: $($_.Exception.Message)" -ForegroundColor Yellow
      if ($a -eq $Attempts) { throw }
      Start-Sleep -Seconds $DelaySeconds
    }
  }
}

Write-Host "Creating / updating resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force | Out-Null

Write-Host "Creating / updating network security group $networkSecurityGroupName ..."
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $networkSecurityGroupName -ErrorAction SilentlyContinue

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name "SSH" -Protocol Tcp -Direction Inbound -Priority 1001 `
  -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name "HTTP-8080" -Protocol Tcp -Direction Inbound -Priority 1002 `
  -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow

if (-not $nsg) {
  New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName `
    -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP | Out-Null
  $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $networkSecurityGroupName
} else {
  $nsg.SecurityRules.Clear()
  $nsg.SecurityRules.Add($nsgRuleSSH)
  $nsg.SecurityRules.Add($nsgRuleHTTP)
  $nsg | Set-AzNetworkSecurityGroup | Out-Null
}

Write-Host "Creating / updating VNet $virtualNetworkName and subnet $subnetName ..."
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName -ErrorAction SilentlyContinue

if (-not $vnet) {
  $subnetCfg = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
  New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location `
    -AddressPrefix $vnetAddressPrefix -Subnet $subnetCfg | Out-Null
  $vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName
} else {
  $sub = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }
  if (-not $sub) {
    Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $subnetAddressPrefix | Out-Null
    $vnet | Set-AzVirtualNetwork | Out-Null
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName
  }
}

Write-Host "Creating / updating SSH key resource $sshKeyName ..."
$existingKey = Get-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -ErrorAction SilentlyContinue
if (-not $existingKey) {
  New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey | Out-Null
}

Start-Sleep 8

for ($i = 0; $i -lt $vmNames.Count; $i++) {
  $name = $vmNames[$i]
  $zone = $vmZones[$i]

  Write-Host "Creating VM $name in zone $zone using image $vmImage ..."
  Invoke-WithRetry -Attempts 4 -DelaySeconds 15 -Script {
    New-AzVM `
      -ResourceGroupName $resourceGroupName `
      -Name $name `
      -Location $location `
      -Zone $zone `
      -Image $vmImage `
      -Size $vmSize `
      -Credential $cred `
      -VirtualNetworkName $virtualNetworkName `
      -SubnetName $subnetName `
      -SecurityGroupName $networkSecurityGroupName `
      -SshKeyName $sshKeyName `
      -Verbose | Out-Null
  }
}

Write-Host ""
Write-Host "DONE. Check VMs:"
Get-AzVM -ResourceGroupName $resourceGroupName | Select Name, Location, Zones
