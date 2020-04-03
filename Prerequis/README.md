# 3 VM Windows Server (un controleur AD DS et deux seveurs membres)

**Prerequis pour Windows Virtual Desktop:**</br>

- Un controleur de domaine (AD DS), un disque data pour le Sysvol et deux OU (Utilisateurs et Hosts WVD)
- Un serveur membre du domaine AD DS avec l'installation AD Connect (reste à executer l'assistant Azure AD Connect)
- Un serveur membre du domaine AD DS avec un disque data pour le stockcage des profils (FSLogix)
- Un service Azure Bastion pour l'administration

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FPierre-Chesne%2FQuickStart-WindowsVirtualDesktop%2Fmaster%2FPrerequis%2Fazuredeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/></a>

