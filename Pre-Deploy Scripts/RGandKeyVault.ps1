#
# RGandKeyValut.ps1
#
$rgName = 'RG-ALB-DSC'

$kVaultName = 'KVALBDSCEastUS2'

$location = 'EastUS2'

$AdminUserName = 'ALBAdmin'



New-AzureRmResourceGroup -Name $rgName -Location $Location

Get-AzureRmResourceGroup -Name $rgName -Location $Location 



New-AzureRmKeyVault -ResourceGroupName $rgName -VaultName $kVaultName -Location $location -Sku premium -EnabledForTemplateDeployment

#Get-AzureRmKeyVault -VaultName contoso -ResourceGroupName rgglobal | Remove-AzureRmKeyVault



# ------- Above this line is required, below this line is optional



# You can also create Secrets/Credentials via the Visual Studio GUI at deployment time.

## You just need the KeyVault pre-created.



$Secret = Read-Host -AsSecureString -Prompt "Enter the Password for $AdminUserName"

Set-AzureKeyVaultSecret -VaultName $kVaultName -Name $AdminUserName -SecretValue $Secret -ContentType txt

#Set-AzureKeyVaultSecret -VaultName "Contoso" -Name "ITSecret" -SecretValue $Secret -Expires $Expires -NotBefore $NBF -ContentType $ContentType -Enable $True -Tags $Tags -PassThru



$ALBDSC = Get-AzureKeyVaultSecret -VaultName $kVaultName -Name $AdminUserName

$ALBDSC.Id

$ALBDSC.SecretValue      # SecureString

$ALBDSC.SecretValueText  # Text

$ALBDSC | gm

$ALBDSC | select *



# most recent key

# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang



# specific version of key

# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang/afa351084bba48449cc5deb984c7c4a1
=




# ------- Above this line is required, below this line is optional

# Save the storage account key in the keyvault
#
#$rgName = 'rgGlobal'
#
#$saname = 'saeastus2'
#
#$SS = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $saname)[1].value | ConvertTo-SecureString -AsPlainText -Force
#
#Set-AzureKeyVaultSecret -VaultName $kVaultName -Name StorageAccountKeySource -SecretValue $SS -ContentType txt