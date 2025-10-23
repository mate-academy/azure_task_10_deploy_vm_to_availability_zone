[CmdletBinding()]
param(
  [string]$Location = "uksouth",
  [string]$Rg       = "mate-azure-task-10",
  [string]$Vnet     = "vnet",
  [string]$Subnet   = "default",
  [string]$Nsg      = "defaultnsg",
  [string]$SshRes   = "linuxboxsshkey",
  [string]$Vm1      = "matebox-az1",
  [string]$Vm2      = "matebox-az2",
  [string]$VmSize   = "Standard_B1s",
  [string]$Image    = "Ubuntu2204",
  [string]$PubKey   = "$HOME/.ssh/id_rsa.pub"
)

Write-Host "==> Deploying 2 VMs to different AZs in $Location"

# ---------- Resource Group ----------
if (-not (Get-AzResourceGroup -Name $Rg -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $Rg -Location $Location | Out-Null
}

# ---------- NSG (ssh/http — не зашкодить, навіть без публічного IP) ----------
$nsgObj = Get-AzNetworkSecurityGroup -ResourceGroupName $Rg -Name $Nsg -ErrorAction SilentlyContinue
if (-not $nsgObj) {
  $ssh  = New-AzNetworkSecurityRuleConfig -Name "ssh"  -Direction Inbound -Protocol Tcp -Priority 1000 `
          -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
  $http = New-AzNetworkSecurityRuleConfig -Name "http" -Direction Inbound -Protocol Tcp -Priority 1001 `
          -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
  $nsgObj = New-AzNetworkSecurityGroup -Name $Nsg -ResourceGroupName $Rg -Location $Location -SecurityRules $ssh,$http
}

# ---------- VNet + Subnet (NSG на subnet) ----------
$vnetObj = Get-AzVirtualNetwork -Name $Vnet -ResourceGroupName $Rg -ErrorAction SilentlyContinue
if (-not $vnetObj) {
  $snCfg = New-AzVirtualNetworkSubnetConfig -Name $Subnet -AddressPrefix "10.10.1.0/24" -NetworkSecurityGroup $nsgObj
  $vnetObj = New-AzVirtualNetwork -Name $Vnet -ResourceGroupName $Rg -Location $Location -AddressPrefix "10.10.0.0/16" -Subnet $snCfg
} else {
  $sn = $vnetObj.Subnets | Where-Object Name -eq $Subnet
  if (-not $sn) {
    $sn = Add-AzVirtualNetworkSubnetConfig -Name $Subnet -AddressPrefix "10.10.1.0/24" -VirtualNetwork $vnetObj -NetworkSecurityGroup $nsgObj
    $vnetObj | Set-AzVirtualNetwork | Out-Null
  } elseif (-not $sn.NetworkSecurityGroup) {
    $sn.NetworkSecurityGroup = $nsgObj
    $vnetObj | Set-AzVirtualNetwork | Out-Null
  }
}

# ---------- SSH Key ресурс (не передаємо порожній ключ) ----------
$pubKeyText = $null
if (Test-Path -LiteralPath $PubKey) {
  $pubKeyText = (Get-Content -LiteralPath $PubKey -Raw).Trim()
}
$sshKeyRes = Get-AzSshKey -ResourceGroupName $Rg -Name $SshRes -ErrorAction SilentlyContinue
if (-not $sshKeyRes) {
  if ([string]::IsNullOrWhiteSpace($pubKeyText)) {
    $sshKeyRes = New-AzSshKey -ResourceGroupName $Rg -Name $SshRes
    Write-Host "⚠️  SSH public key file not found at '$PubKey'. Resource created WITHOUT uploaded key."
  } else {
    $sshKeyRes = New-AzSshKey -ResourceGroupName $Rg -Name $SshRes -PublicKey $pubKeyText
  }
}

# ---------- Helper: створення ВМ в конкретній зоні ----------
function New-ZonalVm {
  param(
    [string]$Name,
    [string]$Zone
  )
  if (-not (Get-AzVM -Name $Name -ResourceGroupName $Rg -ErrorAction SilentlyContinue)) {
New-AzVM `
  -ResourceGroupName $Rg `
  -Location $Location `
  -Name $Name `
  -Image $Image `
  -Size $VmSize `
  -VirtualNetworkName $Vnet `
  -SubnetName $Subnet `
  -SecurityGroupName $Nsg `
  -SshKeyName $SshRes `
  -Zone $Zone | Out-Null
  } else {
    Write-Host "ℹ️  VM '$Name' already exists — skip."
  }
}

# ---------- 2 ВМ у двох зонах ----------
New-ZonalVm -Name $Vm1 -Zone '1'
New-ZonalVm -Name $Vm2 -Zone '2'

# ---------- Артефакт: result.json ----------
$vms = @(
  Get-AzVM -ResourceGroupName $Rg -Name $Vm1 | Select-Object @{n='Name';e={$_.Name}}, @{n='Zone';e={$_.Zones[0]}}, Location
  Get-AzVM -ResourceGroupName $Rg -Name $Vm2 | Select-Object @{n='Name';e={$_.Name}}, @{n='Zone';e={$_.Zones[0]}}, Location
)
@($vms) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "result.json" -Encoding UTF8

Write-Host "==> Done. VMs:"
$vms | Format-Table
