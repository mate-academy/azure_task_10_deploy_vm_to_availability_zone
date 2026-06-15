$ErrorActionPreference = "Stop"

# Region: any zone-capable region (README); adjust if subscription hits B1s capacity in a region.
# If your subscription blocks Standard_B1s or zone capacity, that is an account limit; the script still matches the spec.
$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$vmNames = @("matebox-a", "matebox-b")
$vmZones = @("1", "2")

Write-Host "Deploying to region: $location"

$sshPublicKeyPath = Join-Path $HOME ".ssh/id_ed25519.pub"
if (-not (Test-Path $sshPublicKeyPath)) {
    $sshPublicKeyPath = Join-Path $HOME ".ssh/id_rsa.pub"
}
$sshKeyPublicKey = Get-Content -Path $sshPublicKeyPath -Raw
$secPlain = ConvertTo-SecureString "N0tUsedForLogin!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $secPlain)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 `
    -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 `
    -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
$nsg = New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName `
    -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Creating virtual network $virtualNetworkName ..."
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location `
    -AddressPrefix $vnetAddressPrefix -Subnet $subnet

Write-Host "Creating SSH key resource $sshKeyName ..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -Location $location -PublicKey $sshKeyPublicKey

for ($i = 0; $i -lt $vmNames.Count; $i++) {
    $vmName = $vmNames[$i]
    $vmZone = $vmZones[$i]
    Write-Host "Creating VM $vmName in zone $vmZone ..."
    $newVmParams = @{
        ResourceGroupName    = $resourceGroupName
        Name                 = $vmName
        Location             = $location
        Image                = $vmImage
        Size                 = $vmSize
        SubnetName           = $subnetName
        VirtualNetworkName   = $virtualNetworkName
        SecurityGroupName    = $networkSecurityGroupName
        SshKeyName           = $sshKeyName
        Zone                 = $vmZone
        Credential           = $cred
    }
    New-AzVM @newVmParams
}
