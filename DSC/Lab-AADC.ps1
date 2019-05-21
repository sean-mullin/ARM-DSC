configuration Main
{

    Param ( 
        [String]$DomainName,
        [PSCredential]$AdminCreds,
        [Int]$RetryCount = 30,
        [Int]$RetryIntervalSec = 120,
        [String]$ThumbPrint
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xPSDesiredStateConfiguration
	Import-DscResource -ModuleName xActiveDirectory 
    Import-DscResource -ModuleName xPendingReboot 
    Import-DscResource -ModuleName xComputerManagement
	
    [PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$($AdminCreds.UserName)", $AdminCreds.Password)

    node localhost
    {
        Write-Verbose -Message $Nodename -Verbose

        LocalConfigurationManager 
        {
            ActionAfterReboot    = 'ContinueConfiguration'
            ConfigurationMode    = 'ApplyandMonitor'
            RebootNodeIfNeeded   = $true
            AllowModuleOverWrite = $true
        }

		file aadc
		{
			Type = 'Directory'
			Ensure = 'Present'
			DestinationPath = 'c:\aadc'
		}

		xWaitForADDomain ADFS
        {
            DomainName           = $DomainName
            RetryCount           = $RetryCount
            RetryIntervalSec     = $RetryIntervalSec
            DomainUserCredential = $DomainCreds
        }

		xComputer JoinDomain
		{
			Name                  = $env:ComputerName 
			DomainName            = $DomainName
			Credential            = $DomainCreds  
			DependsOn             = '[xWaitForADDomain]ADFS'

		}

		xPendingReboot DomainJoin
        {
            Name      = 'RebootForDomainJoin'
            DependsOn = '[xComputer]JoinDomain'
        }

		xremotefile DownloadMsi
		{
            DependsOn = '[file]aadc','[xPendingReboot]Domainjoin'
			DestinationPath = 'c:\aadc'
			Uri = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
        }
		
        
    }
}