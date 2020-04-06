##################################################################################################
# Script:                                                                                        # 
# - recupere les utilisateurs dans un groupe Azure AD                                            #
# - Assigne les permissions aux utlisateurs de consommer un "app group" dans un "Host Pool"      #  
# Pour executer ce script il faut les modules PowerShell "Azure AD" et "Windows Virtual Desktop" #
##################################################################################################



# Connexion Azure AD
Connect-AzureAD
# Connexion WVD
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"


$IdGroup = "8c4ff8b0-9d60-483e-985a-31008c4b396a"
$MonTenantWVD = "WVD-Tenant-00"
$MonHostPool = "hostpool-000"
$MonAppGroupName = "Desktop Application Group"
$ListUsers = @(Get-AzureADGroupMember -ObjectId $IdGroup | select UserPrincipalName)


foreach ($Users in $ListUsers){	
    Add-RdsAppGroupUser `
        -TenantName $MonTenantWVD `
        -HostPoolName $MonHostPool `
        -AppGroupName $MonAppGroupName `
        -UserPrincipalName $Users.UserPrincipalName
}