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
    Import-DscResource -ModuleName xStorage
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

        WindowsFeature InstallADDS 
        {            
            Ensure               = "Present"
            Name                 = "AD-Domain-Services"
            IncludeAllSubFeature = $true
        }

        WindowsFeature ADTools 
        {
            Ensure = "Present"
            Name   = "RSAT-ADDS"
        }

        xDisk FDrive 
        {
            DiskID      = "2"
            DriveLetter = 'F' 
        }

        xADDomain DC1 
        {
            DomainName                    = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath                  = 'F:\NTDS'
            LogPath                       = 'F:\NTDS'
            SysvolPath                    = 'F:\SYSVOL'
            DependsOn                     = "[WindowsFeature]InstallADDS", '[xDisk]FDrive'
        }

        xWaitForADDomain DC1 
        {
            DependsOn            = '[xADDomain]DC1'
            DomainName           = $DomainName
            RetryCount           = $RetryCount
            RetryIntervalSec     = $RetryIntervalSec
            DomainUserCredential = $DomainCreds
        }

        xADRecycleBin RecycleBin
        {
            EnterpriseAdministratorCredential = $DomainCreds
            ForestFQDN                        = $DomainName
            DependsOn                         = '[xWaitForADDomain]DC1'
        }

		script setDNS
		{
			DependsOn = '[xADRecycleBin]RecycleBin'
			getscript = {
               return @{
               result = [string]$(netsh interface ip show config)}
                }
       
			setscript = {

				Write-Verbose "Setting Ethernet DNS to DHCP"
                netsh interface ip set dns "Ethernet" dhcp
				netsh interface ipv6 set dns "Ethernet" dhcp
}
            testscript = {
						(Get-DnsClientServerAddress -InterfaceAlias Ethernet* -AddressFamily IPV4 | 
						Foreach {! ($_.ServerAddresses -contains '127.0.0.1')}) -notcontains $false
            }

		}
        xPendingReboot RebootForPromo 
        {
            Name      = 'RebootForPromo'
            DependsOn = '[xADDomain]DC1'
        }

        
    }
}