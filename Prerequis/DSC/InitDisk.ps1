configuration InitDisk
{ 
    param 
    () 
    
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