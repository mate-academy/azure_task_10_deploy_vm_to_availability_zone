$rg  = "mate-azure-task-10"
$loc = "canadacentral"
$size = "Standard_D2s_v3"

New-AzResourceGroup `
    -Name $rg `
    -Location $loc `
    -Force

$sshKeyName = "linuxboxsshkey"
$sshPath = "$HOME\.ssh\linuxboxsshkey"

if (Test-Path $sshPath) {
    Remove-Item $sshPath -Force -ErrorAction SilentlyContinue
}

if (Test-Path "$sshPath.pub") {
    Remove-Item "$sshPath.pub" -Force -ErrorAction SilentlyContinue
}

ssh-keygen -t rsa -b 4096 -f $sshPath -N '""' | Out-Null

$pubKey = Get-Content "$sshPath.pub" -Raw

Remove-AzSshKey `
    -ResourceGroupName $rg `
    -Name $sshKeyName `
    -ErrorAction SilentlyContinue

New-AzSshKey `
    -ResourceGroupName $rg `
    -Name $sshKeyName `
    -PublicKey $pubKey `
    -Location $loc

$nsgRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowSSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22 `
    -Access Allow

$nsg = New-AzNetworkSecurityGroup `
    -Name "defaultnsg" `
    -ResourceGroupName $rg `
    -Location $loc `
    -SecurityRules $nsgRule

$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name "default" `
    -AddressPrefix "10.0.0.0/24"

$vnet = New-AzVirtualNetwork `
    -Name "vnet" `
    -ResourceGroupName $rg `
    -Location $loc `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnet

for ($i = 1; $i -le 2; $i++) {

    $vmName = "matebox$i"

    Write-Host "Deploying $vmName in Zone $i..." -ForegroundColor Cyan

    New-AzVM `
        -ResourceGroupName $rg `
        -Location $loc `
        -Name $vmName `
        -VirtualNetworkName "vnet" `
        -SubnetName "default" `
        -SecurityGroupName "defaultnsg" `
        -ImageName "Ubuntu2204" `
        -Size $size `
        -Zone $i `
        -SshKeyName $sshKeyName `
        -PublicIpAddressName ""
}