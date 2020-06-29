##############################################################################
# Script de déploiement d'un Host pool Windows Virtual Desktop (Spring 2020) #
# Déploiement automatiquement :                                              #
# - Host pool                                                                #
# - Desktop Application groups                                               #
# - Workspace                                                                #
# - Assignation d'un groupe Azure AD à l'Application Group"                  #
# - VM Windows 10 multi Users + Office 365                                   #
# - Ajout de la VM dans Active Directory                                     #
# - Ajout de la VM en session host dans le Host pool (PowerShell DSC)        # 
#                                                                            #
# Rérequis :                                                                 #
# Vnet existant avec un controleur de domaine joignable                      #
# Auteurs Pascal Sauliere et Pierre Chesne                                   # 
##############################################################################

# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7#powershell-core
# https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/?view=azps-4.2.0

# Nouveau Module
#Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Connexion Abonnemment
#Connect-AzAccount

# Variables
$rgName = "RG-WVD-PS" # Nom du ressource groupe
$location = "eastus2" # Region

# Variables Host Pool
$hostpoolName = "Host-Pool-PS" # Nom du Host pool
$workspaceName = "Workspace-PS" # Nom du workspace
$dagName = "Host-Pool-PS-DAG" # Nom du Desktop Application Group 
$typePool = "Pooled" # Type de pool Pooled | Personal
$typeLB = "BreadthFirst" # Type de Load Balancer BreathFirst | DepthFirst
$idGroupAzureAD = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # ID Goupe Azure

# Variables VM (host)
$vmAdminUsername = Read-Host "Compte admin local de la VM" # Compte Admin local de la vm
$vmAdminPassword = Read-Host "Password" -AsSecureString
$azureVmName = "Host-PS-01" # nom de la vm
$azureVmOsDiskName = "Host-PS-01-OS" # nom du disk OS
$azureVmSize = "Standard_D2s_v3" # Taille de la vm
$azureNicName = "Host-PS-01-NIC" # nom de la nic
$azureResourceGroupVnet = "RG-AD-WVD" # nom du resource groupe du Vnet (joignable par un controleur de doimaine Windows)
$azureVnetName = "AD-WVD-vnet" # nom du vnet
$azureVnetSubnetName = "subnet-test" # nom du subnet
$azureVmPublisherName = "MicrosoftWindowsDesktop" # Publisher OS
$azureVmOffer = "office-365" # Offer
$azureVmSkus = "19h2-evd-o365pp" # Windows 10 Multi-User Office 365

# Variable ajout de la VM dans l'AD
$domainAD = Read-Host "Nom du domaine Active Directory (ex: ma-pme.loal)" # nom du domaine Active Directory
$vmAdminUsernameAD = Read-Host "Compte Utilisateur de l'Active Directory ayant les droits d'ajouter un compte ordinateur dans le domaine AD (ex: user@ma-pme.loal)" # Compte Active Directory ayant le droit de créer un compte machine dans l'Active Directory (Windows Server)
$vmAdminPasswordAD = Read-Host "Password" -AsSecureString

# Variables Installation des agents
$AgentstorageAccountName = "wdvagent007" # nom du compte de stockage pour le stockage du script Powershell DCS (Agent WVD)
$containerName = "dsc" # nom du contenaire
$repLocal = "c:\tempoAgent" # nom du repertoire local pour renommage

# Creation du Ressource Groupe
Write-Host "Creation du resource groupe" -ForegroundColor yellow
New-AzResourceGroup `
  -Name $rgName `
  -Location $location

# Creation d'un host pool avec un Workspace et Application group
Write-Host "Creation du Host Pool" -ForegroundColor yellow
New-AzWvdHostPool `
  -Name $hostpoolName `
  -ResourceGroupName $rgName `
  -Location $location `
  -HostPoolType $typePool `
  -LoadBalancerType $typeLB `
  -WorkspaceName $workspaceName `
  -DesktopAppGroupName $dagName 

# Creation d'une cle d'enregistrement du "host Pool"
Write-Host "Creation cle d'enregistrement du host Pool" -ForegroundColor yellow
 New-AzWvdRegistrationInfo `
   -ResourceGroupName $rgName `
   -HostPoolName $hostpoolName `
   -ExpirationTime $((get-date).ToUniversalTime().AddHours(2).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))

# Recuperation de la cle d'enregistrement du "host Pool"
$GetKey = Get-AzWvdRegistrationInfo -ResourceGroupName $rgName -HostPoolName $hostpoolName
$key = $GetKey.Token

# Assignement d'un groupe à la DAG
Write-Host "Assignement des droits au groupe Azure AD" -ForegroundColor yellow
New-AzRoleAssignment `
  -ObjectId $idGroupAzureAD `
  -RoleDefinitionName "Desktop Virtualization User" `
  -ResourceName $dagName `
  -ResourceGroupName $rgName `
  -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

# Creation d'une VM "Windows 10 multi user + Office 365"
Write-Host "Creation de la VM" -ForegroundColor yellow
$vmCredential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, $vmAdminPassword)
$azureVnetSubnet = (Get-AzVirtualNetwork -Name $azureVnetName -ResourceGroupName $azureResourceGroupVnet).Subnets | Where-Object {$_.Name -eq $azureVnetSubnetName}
$azureNIC = New-AzNetworkInterface -Name $azureNicName -ResourceGroupName $rgName -Location $location -SubnetId $azureVnetSubnet.Id
$VirtualMachine = New-AzVMConfig -VMName $azureVmName -VMSize $azureVmSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $azureVmName -Credential $vmCredential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azureNIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $azureVmPublisherName -Offer $azureVmOffer -Skus $azureVmSkus -Version "latest"
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -StorageAccountType "Premium_LRS" -Caching ReadWrite -Name $azureVmOsDiskName -CreateOption FromImage
New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -Verbose -DisableBginfoExtension

# VM qui joint le domaine AD
Write-Host "Ajout de la VM au domaine Active Directory" -ForegroundColor yellow
$vmCredentialAD = New-Object System.Management.Automation.PSCredential ($vmAdminUsernameAD, $vmAdminPasswordAD)
Set-AzVMADDomainExtension -ResourceGroupName $rgName -VMName $azureVmName -DomainName $domainAD -JoinOption 3 -Credential $vmCredentialAD

# Creation d'un compte stockage (pour les agents)
Write-Host "Creation du compte de stockage pour les agents WVD" -ForegroundColor yellow
New-AzStorageAccount -ResourceGroupName $rgName `
  -Name $AgentstorageAccountName `
  -Location $location `
  -SkuName Standard_LRS

# Récuperation des cles du compte de stockage et du context
$keyStorage = Get-AzStorageAccountKey -ResourceGroupName $rgName -Name $AgentstorageAccountName
$keyStorage.Value[0]
$ctx = New-AzStorageContext -StorageAccountName $AgentstorageAccountName -StorageAccountKey $keyStorage.Value[0]

# Creation d'un blob storage
Write-Host "Creation du container" -ForegroundColor yellow
New-AzStorageContainer `
  -Name $containerName `
  -Context $ctx.Context `
  -Permission Container

# Recuperation des Agents WVD
Write-Host "Recuperation des agents" -ForegroundColor yellow
mkdir $repLocal
Set-Location -Path $repLocal
$uri = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
Invoke-WebRequest -Uri $uri -OutFile ".\Configuration.ps1.zip"
Set-AzStorageBlobContent -Container "dsc" -File "$repLocal\Configuration.ps1.zip" -Blob "Configuration.ps1.zip" -Context $ctx.Context

# Installation des agents WVD en Powershell DSC
Write-Host "Installation des agents" -ForegroundColor yellow
$argument = @{hostPoolName=$hostpoolName; registrationInfoToken=$key}
Set-AzVMDscExtension `
  -ResourceGroupName $rgName `
  -VMName $azureVmName `
  -ArchiveBlobName "Configuration.ps1.zip" -ArchiveStorageAccountName $AgentstorageAccountName `
  -ArchiveResourceGroupName $rgName `
  -ConfigurationName "AddSessionHost" `
  -ConfigurationArgument $argument `
  -ArchiveContainerName $containerName `
  -Version "2.73" -Location $location

  Write-Host "https://rdweb.wvd.microsoft.com/arm/webclient/index.html" -ForegroundColor yellow




