########################
#Clean Azure AD Connect#
########################
Install-Module -Name MSonline
$msolcred = get-credential
connect-msolservice -credential $msolcred
Set-MsolDirSyncEnabled -EnableDirSync $false
(Get-MSOLCompanyInformation).DirectorySynchronizationEnabled



