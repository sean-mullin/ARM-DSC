#
# get-dscmodules.ps1
#
# break
#
# This script will remove old modules and download the newest versions
$Modules = @('xPSDesiredStateConfiguration','xActiveDirectory','xStorage','xPendingReboot',
	'xComputerManagement','xnetworking','NTFSSecurity','xDnsServer')
# remove old version of the Modules/Resources
Get-Module -ListAvailable -Name  $Modules | foreach {
    $_.ModuleBase | Remove-Item -Recurse -Force
}
# Bootstrap the nuget agent
Find-Package -ForceBootstrap -Name xComputerManagement

# Install new versions of the modules
Install-Package -name $Modules -Force -AllowClobber
Get-Module -Name $Modules -ListAvailable