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
		
        WindowsFeature InstallADFS 
        {            
            Ensure               = "Present"
            Name                 = "ADFS-Federation"
            IncludeAllSubFeature = $true
			DependsOn = '[xPendingReboot]DomainJoin'
        }
        
    }
}