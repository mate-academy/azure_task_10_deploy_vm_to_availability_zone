$ErrorActionPreference = "Stop"

$location = "indiasouthcentral"
$resourceGroupName = "mate-azure-task-10"

$networkSecurityGroupName = "defaultnsg"

$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"
$sshPrivateKeyPath = Join-Path $HOME ".ssh/vm-demo-key"
$sshPublicKeyPath = "$sshPrivateKeyPath.pub"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$adminUsername = "azureuser"

$vmDefinitions = @(
    @{
        Name = "matebox1"
        Zone = "1"
    },
    @{
        Name = "matebox2"
        Zone = "2"
    }
)

if (-not (Test-Path $sshPublicKeyPath)) {
    throw "SSH public key was not found: $sshPublicKeyPath"
}

$sshKeyPublicKey = (Get-Content $sshPublicKeyPath -Raw).Trim()

Write-Host "Creating resource group $resourceGroupName ..."

$resourceGroup = New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location

Write-Host "Creating network security group $networkSecurityGroupName ..."

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22 `
    -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 8080 `
    -Access Allow

$nsg = New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Creating subnet $subnetName ..."

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix `
    -NetworkSecurityGroup $nsg

Write-Host "Creating virtual network $virtualNetworkName ..."

$vnet = New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnetConfig

Write-Host "Creating Azure SSH key resource $sshKeyName ..."

$sshKey = New-AzSshKey `
    -Name $sshKeyName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -PublicKey $sshKeyPublicKey

# New-AzVM requires a credential object even when SSH authentication is used.
# A generated password prevents us from storing a real password in Git.
$randomPassword = "$([guid]::NewGuid().ToString())aA1!"

$securePassword = ConvertTo-SecureString `
    -String $randomPassword `
    -AsPlainText `
    -Force

$credential = [PSCredential]::new(
    $adminUsername,
    $securePassword
)

foreach ($vmDefinition in $vmDefinitions) {
    $vmName = $vmDefinition.Name
    $zone = $vmDefinition.Zone

    Write-Host "Creating VM $vmName in availability zone $zone ..."

    New-AzVM `
        -ResourceGroupName $resourceGroupName `
        -Name $vmName `
        -Location $location `
        -Zone $zone `
        -Image $vmImage `
        -Size $vmSize `
        -Credential $credential `
        -VirtualNetworkName $virtualNetworkName `
        -AddressPrefix $vnetAddressPrefix `
        -SubnetName $subnetName `
        -SubnetAddressPrefix $subnetAddressPrefix `
        -SecurityGroupName $networkSecurityGroupName `
        -SshKeyName $sshKeyName `
        -PublicIpAddressName "" `
        -SecurityType Standard `
        -OSDiskDeleteOption Delete `
        -NetworkInterfaceDeleteOption Delete
}

Write-Host "Deployment completed."

Get-AzVM `
    -ResourceGroupName $resourceGroupName |
    Select-Object `
        Name,
        @{Name = "Zone"; Expression = { $_.Zones -join "," }},
        ProvisioningState