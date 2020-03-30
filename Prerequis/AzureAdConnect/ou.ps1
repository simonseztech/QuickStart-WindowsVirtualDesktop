param( 
[parameter(Mandatory=$true)][string]$ouUsers,
[parameter(Mandatory=$true)][string]$ouHosts
)

New-ADOrganizationalUnit -Name $ouUsers
New-ADOrganizationalUnit -Name $ouHosts


