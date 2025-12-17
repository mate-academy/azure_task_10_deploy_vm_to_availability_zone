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

# admin-учетка нужна для создания VM (даже если вход по SSH-ключу)
$adminUsername = "azureuser"
$plainPassword = "P@ss" + (Get-Random -Minimum 10000000 -Maximum 99999999) + "aA!"
$adminPassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

function Invoke-WithRetry {
  param(
    [Parameter(Mandatory=$true)][ScriptBlock]$Script,
    [int]$Attempts = 4,
    [int]$DelaySeconds = 10
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

$subnetId = ($vnet.Subnets | Where-Object { $_.Name -eq $subnetName }).Id
if (-not $subnetId) { throw "SubnetId is empty. Check that subnet '$subnetName' exists in VNet '$virtualNetworkName'." }

Write-Host "Creating / updating SSH key resource $sshKeyName ..."
$existingKey = Get-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -ErrorAction SilentlyContinue
if (-not $existingKey) {
  New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey | Out-Null
}

Start-Sleep 10  # чтобы ARM “успел” увидеть ресурсы

for ($i = 0; $i -lt $vmNames.Count; $i++) {
  $name = $vmNames[$i]
  $zone = $vmZones[$i]

  Write-Host "Creating NIC for $name (no Public IP) ..."
  $nicName = "$name-nic"

  $oldNic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -ErrorAction SilentlyContinue
  if ($oldNic) { Remove-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -Force }

  $nic = New-AzNetworkInterface `
    -Name $nicName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SubnetId $subnetId `
    -NetworkSecurityGroupId $nsg.Id

  Write-Host "Creating VM $name in zone $zone ..."
  $vm = New-AzVMConfig -VMName $name -VMSize $vmSize

  $vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName $name -Credential $cred -DisablePasswordAuthentication

  $vm = Add-AzVMSshPublicKey -VM $vm -KeyData $sshKeyPublicKey -Path "/home/$adminUsername/.ssh/authorized_keys"

  $vm = Set-AzVMSourceImage -VM $vm -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest"

  $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id -Primary

  # (опционально) отключаем boot diagnostics
  try { $vm = Set-AzVMBootDiagnostic -VM $vm -Disable } catch { }

  Invoke-WithRetry -Attempts 4 -DelaySeconds 12 -Script {
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm -Zone $zone -Verbose | Out-Null
  }
}

Write-Host ""
Write-Host "DONE. Check VMs:"
Get-AzVM -ResourceGroupName $resourceGroupName | Select Name, Location, Zones
