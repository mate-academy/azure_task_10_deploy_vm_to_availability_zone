<#
  Read First:
  1)  to see documentation for the commands below use:
      Get-Help $Your_CmdLet -Full
  2)  to see available values for specific parameters below use:
      Get-Help $Your_CmdLet -Parameter $Your_Parameter
  3)  This Template is designed for
        - creating separate NEW Resource Group
        - creating X count of VM's in the X count of Availability Zones
        - SSH authentification
        - password still necessary for admin privilages
        - Cost-Free deploying in terms of Azure Free Account Subscription
          Therefore:
          - PublicIP settings & VMConfig section is commented
              Since "Basic" Sku parameter is deprecated
              within the Availability Zones
          - As a result of tht ^^ Regular connection from outside internet
              is not available
      * PublicIP Settings & section are present for personal future use
  4)  Set preferred settings below:
#>

# general settings:
$location =                 "uksouth"
$resourceGroupName =        "mate-azure-task-10"

# Network Security Group settings:
$networkSecurityGroupName = "defaultnsg"

# Virtual Network settings:
$virtualNetworkName =       "vnet"
$subnetName =               "default"
$vnetAddressPrefix =        "10.0.0.0/16"
$subnetAddressPrefix =      "10.0.0.0/24"

# public Ip settings:
# $publicIpAddressName =      "linuxboxpip"
# $publicIpDnsprefix =        "mateacademyyegortask10"
# $publicIpSku =              "Standard"
# $publicIpAllocation =       "Dynamic"

# Network Interface settings:
$nicName =                  "NetInterface"
$ipConfigName =             "ipConfig1"

# SSH settings:
$sshKeyName =               "linuxboxsshkey"
$sshKeyPublicKey =          Get-Content "~/.ssh/id_rsa.pub"

# VM settings:
$vmName =                   "matebox"
$vmSecurityType =           "Standard"
$vmSize =                   "Standard_B1s"

# Boot Diagnostic Storage Account settings
$bootStorageAccName =       "bootdiagnosstorageacc"
$bootStSkuName =            "Standard_LRS"
$bootStKind =               "StorageV2"
$bootStAccessTier =         "Hot"
$bootStMinimumTlsVersion =  "TLS1_0"

# OS settings:
# manually configure Linux / Windows in "Set-AzVMOperatingSystem" section
$osUser =                   "yegor"
$osUserPassword =           "P@ssw0rd1234"
$osPublisherName =          "Canonical"
$osOffer =                  "0001-com-ubuntu-server-jammy"
$osSku =                    "22_04-lts-gen2"
$osVersion =                "latest"
$osDiskSizeGB =             64
$osDiskType =               "Premium_LRS"

# Availability Settings:
$AvZonesCount =             2


Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup `
  -Name                     $resourceGroupName `
  -Location                 $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name                     SSH `
  -Protocol                 Tcp `
  -Direction                Inbound `
  -Priority                 1001 `
  -SourceAddressPrefix      * `
  -SourcePortRange          * `
  -DestinationAddressPrefix * `
  -DestinationPortRange     22 `
  -Access                   Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
  -Name                     HTTP `
  -Protocol                 Tcp `
  -Direction                Inbound `
  -Priority                 1002 `
  -SourceAddressPrefix      * `
  -SourcePortRange          * `
  -DestinationAddressPrefix * `
  -DestinationPortRange     8080 `
  -Access                   Allow
New-AzNetworkSecurityGroup `
  -Name                     $networkSecurityGroupName `
  -ResourceGroupName        $resourceGroupName `
  -Location                 $location `
  -SecurityRules            $nsgRuleSSH, $nsgRuleHTTP
$networkSecurityGroupObj = Get-AzNetworkSecurityGroup `
  -Name                     $networkSecurityGroupName `
  -ResourceGroupName        $resourceGroupName

Write-Host "Creating a virtual network $virtualNetworkName ..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name                     $subnetName `
  -AddressPrefix            $subnetAddressPrefix `
  -NetworkSecurityGroup     $networkSecurityGroupObj
New-AzVirtualNetwork `
  -Name                     $virtualNetworkName `
  -ResourceGroupName        $resourceGroupName `
  -Location                 $location `
  -AddressPrefix            $vnetAddressPrefix `
  -Subnet                   $subnetConfig
$vnetObj = Get-AzVirtualNetwork `
  -Name                     $virtualNetworkName `
  -ResourceGroupName        $resourceGroupName
$subnetId = $vnetObj.Subnets[0].Id

Write-Host "Creating an SSH key resource $sshKeyName ..."
New-AzSshKey `
  -Name                     $sshKeyName `
  -ResourceGroupName        $resourceGroupName `
  -PublicKey                $sshKeyPublicKey

Write-Host "Creating Storage Account for boot diagnostic ..."
New-AzStorageAccount `
  -ResourceGroupName        $resourceGroupName `
  -Name                     $bootStorageAccName `
  -Location                 $location `
  -SkuName                  $bootStSkuName `
  -Kind                     $bootStKind `
  -AccessTier               $bootStAccessTier `
  -MinimumTlsVersion        $bootStMinimumTlsVersion

for ($i = 1; $i -le $AvZonesCount; $i++) {
  # $AVZonePublicIpName =       "${publicIpAddressName}${i}"
  # $AVZonePublicIpDnsprefix =  "${publicIpDnsprefix}${i}"
  # Write-Host "Creating a Public IP $AVZonePublicIpName ..."
  # New-AzPublicIpAddress `
  #   -Name                     $AVZonePublicIpName `
  #   -ResourceGroupName        $resourceGroupName `
  #   -Location                 $location `
  #   -Sku                      $publicIpSku `
  #   -AllocationMethod         $publicIpAllocation `
  #   -DomainNameLabel          $AVZonePublicIpDnsprefix `
  #   -Zone                     $i
  # $publicIpObj = Get-AzPublicIpAddress `
  #   -Name                     $AVZonePublicIpName `
  #   -ResourceGroupName        $resourceGroupName

  $AVZoneNicName =            "${nicName}-forVM-${i}"
  $AVZoneIpConfigName =       "${ipConfigName}-forVM-${i}"
  Write-Host "Creating a Network Interface Configuration $AVZoneNicName ..."
  $ipConfig = New-AzNetworkInterfaceIpConfig `
    -Name                     $AVZoneIpConfigName `
    -SubnetId                 $subnetId `
#    -PublicIpAddressId        $publicIpObj.Id
  New-AzNetworkInterface -Force `
    -Name                     $AVZoneNicName `
    -ResourceGroupName        $resourceGroupName `
    -Location                 $location `
    -IpConfiguration          $ipConfig
  $nicObj = Get-AzNetworkInterface `
    -Name                     $AVZoneNicName `
    -ResourceGroupName        $resourceGroupName

  Write-Host "Creating a Virtual Machine ..."
  $SecuredPassword = ConvertTo-SecureString `
    $osUserPassword -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential `
    ($osUser, $SecuredPassword)
  $AVZoneVmName =             "${vmName}-${i}"
  $vmconfig = New-AzVMConfig `
    -VMName                   $AVZoneVmName `
    -VMSize                   $vmSize `
    -SecurityType             $vmSecurityType `
    -Zone                     $i
  $vmconfig = Set-AzVMSourceImage `
    -VM                       $vmconfig `
    -PublisherName            $osPublisherName `
    -Offer                    $osOffer `
    -Skus                     $osSku `
    -Version                  $osVersion
  $vmconfig = Set-AzVMOSDisk `
    -VM                       $vmconfig `
    -Name                     "${vmName}-OSDisk-forVM-${i}" `
    -CreateOption             FromImage `
    -DeleteOption             Delete `
    -DiskSizeInGB             $osDiskSizeGB `
    -Caching                  ReadWrite `
    -StorageAccountType       $osDiskType
  $vmconfig = Set-AzVMOperatingSystem `
    -VM                       $vmconfig `
    -ComputerName             $vmName `
    -Linux                    `
    -Credential               $cred `
    -DisablePasswordAuthentication
  $vmconfig = Add-AzVMNetworkInterface `
    -VM                       $vmconfig `
    -Id                       $nicObj.Id
  $vmconfig = Set-AzVMBootDiagnostic `
    -VM                       $vmconfig `
    -Enable                   `
    -ResourceGroupName        $resourceGroupName `
    -StorageAccountName       $bootStorageAccName
  New-AzVM `
    -ResourceGroupName        $resourceGroupName `
    -Location                 $location `
    -VM                       $vmconfig `
    -SshKeyName               $sshKeyName
}
