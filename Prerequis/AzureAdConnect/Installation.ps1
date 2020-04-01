$SrcAdConnect = "https://raw.githubusercontent.com/Pierre-Chesne/QuickStart-WindowsVirtualDesktop/master/Prerequis/AzureAdConnect/AzureADConnect.msi"
$location = "C:\Windows\Temp\AzureADConnect.msi"

Start-BitsTransfer -Source $SrcAdConnect -Destination $location
C:\Windows\Temp\AzureADConnect.msi /quiet