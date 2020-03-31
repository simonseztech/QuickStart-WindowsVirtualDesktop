configuration InitDisk
{ 
    param 
    ( 
         [Parameter(Mandatory)]
         [String]$DomainName,
 
         [Parameter(Mandatory)]
         [System.Management.Automation.PSCredential]$Admincreds,
 
         [Int]$RetryCount=20,
         [Int]$RetryIntervalSec=30
     ) 
     
     Import-DscResource -ModuleNam xStorage, PSDesiredStateConfiguration
     [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Import-DscResource -ModuleName xStorage

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
        }
        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber  = 2
            DriveLetter = "F"
            DependsOn   = "[xWaitForDisk]Disk2"
        }
    }
} 