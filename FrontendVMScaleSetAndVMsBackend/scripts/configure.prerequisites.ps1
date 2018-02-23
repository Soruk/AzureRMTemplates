<#
    .SYNOPSIS
        Downloads and configures prerequisites application.
#>

Param (   
    [string]$containerName,
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$localResourcesPath
)

Write-Host "Start configuring the Prerequisites"

$argumentsMSIFormat = "/i `"###MSIFILEPATH###`" $Properties /q /l!*vx `"###MSIFILEPATH###.txt`""	
$argumentsEXEFormatOld = "/q /norestart /log `"###EXEFILEPATH###`".txt"
$argumentsEXEFormat = "/install /quiet /norestart /log `"###EXEFILEPATH###`".txt"

# Downloading files from Azure Blob Storage
Write-Host "Downloading Prerequistes"
$context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$blobNameMFCx86 = "MFC.vcredistMFC.x86.exe"    
$blobNameMVCPP2010x86 = "MVCPP.2010.1.vcredist.x86.exe"    
$blobNameMVCPP2010x64 = "MVCPP.2010.1.vcredist.x64.exe"   
$blobNameMVCPP2012x86 = "MVCPP.2012.4.vcredist.x86.exe"    
$blobNameMVCPP2012x64 = "MVCPP.2012.4.vcredist.x64.exe"   
$blobNameMVCPP2013x86 = "MVCPP.2013.0.vcredist.x86.exe"    
$blobNameMVCPP2013x64 = "MVCPP.2013.0.vcredist.x64.exe"   
$blobNameMVCPP2015x86 = "MVCPP.2015.3.vcredist.x86.exe"    
$blobNameMVCPP2015x64 = "MVCPP.2015.3.vcredist.x64.exe"    
$blobNameSqlClrx86 = "SQLSysClrTypes.2016.x86.msi"    
$blobNameSqlClrx64 = "SQLSysClrTypes.2016.x64.msi"
$blobNameSMOx86 = "SharedManagementObjects.2016.x86.msi"    
$blobNameSMOx64 = "SharedManagementObjects.2016.x64.msi"
$blobNameCRx86 = "CRRuntime.13.0.21.x86.msi"    
$blobNameCRx64 = "CRRuntime.13.0.21.x64.msi"

$pathMFCx86 = Join-Path -Path $localResourcesPath $blobNameMFCx86
if (Test-Path -Path $pathMFCx86) {
    Remove-Item -Path $pathMFCx86 -Force 
}
$pathMVCPP2010x86 = Join-Path -Path $localResourcesPath $blobNameMVCPP2010x86
if (Test-Path -Path $pathMVCPP2010x86) {
    Remove-Item -Path $pathMVCPP2010x86 -Force 
}
$pathMVCPP2010x64 = Join-Path -Path $localResourcesPath $blobNameMVCPP2010x64
if (Test-Path -Path $pathMVCPP2010x64) {
    Remove-Item -Path $pathMVCPP2010x64 -Force 
}
$pathMVCPP2012x86 = Join-Path -Path $localResourcesPath $blobNameMVCPP2012x86
if (Test-Path -Path $pathMVCPP2012x86) {
    Remove-Item -Path $pathMVCPP2012x86 -Force 
}
$pathMVCPP2012x64 = Join-Path -Path $localResourcesPath $blobNameMVCPP2012x64
if (Test-Path -Path $pathMVCPP2012x64) {
    Remove-Item -Path $pathMVCPP2012x64 -Force 
}
$pathMVCPP2013x86 = Join-Path -Path $localResourcesPath $blobNameMVCPP2013x86
if (Test-Path -Path $pathMVCPP2013x86) {
    Remove-Item -Path $pathMVCPP2013x86 -Force 
}
$pathMVCPP2013x64 = Join-Path -Path $localResourcesPath $blobNameMVCPP2013x64
if (Test-Path -Path $pathMVCPP2013x64) {
    Remove-Item -Path $pathMVCPP2013x64 -Force 
}
$pathMVCPP2015x86 = Join-Path -Path $localResourcesPath $blobNameMVCPP2015x86
if (Test-Path -Path $pathMVCPP2015x86) {
    Remove-Item -Path $pathMVCPP2015x86 -Force 
}
$pathMVCPP2015x64 = Join-Path -Path $localResourcesPath $blobNameMVCPP2015x64
if (Test-Path -Path $pathMVCPP2015x64) {
    Remove-Item -Path $pathMVCPP2015x64 -Force 
}
$pathSqlClrx86 = Join-Path -Path $localResourcesPath $blobNameSqlClrx86
if (Test-Path -Path $pathSqlClrx86) {
    Remove-Item -Path $pathSqlClrx86 -Force 
}
$pathSqlClrx64 = Join-Path -Path $localResourcesPath $blobNameSqlClrx64
if (Test-Path -Path $pathSqlClrx64) {
    Remove-Item -Path $pathSqlClrx64 -Force 
}
$pathSMOx86 = Join-Path -Path $localResourcesPath $blobNameSMOx86
if (Test-Path -Path $pathSMOx86) {
    Remove-Item -Path $pathSMOx86 -Force 
}
$pathSMOx64 = Join-Path -Path $localResourcesPath $blobNameSMOx64
if (Test-Path -Path $pathSMOx64) {
    Remove-Item -Path $pathSMOx64 -Force 
}
$pathCRx86 = Join-Path -Path $localResourcesPath $blobNameCRx86
if (Test-Path -Path $pathCRx86) {
    Remove-Item -Path $pathCRx86 -Force 
}
$pathCRx64 = Join-Path -Path $localResourcesPath $blobNameCRx64
if (Test-Path -Path $pathCRx64) {
    Remove-Item -Path $pathCRx64 -Force 
}

Get-AzureStorageBlobContent -Blob $blobNameMFCx86 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2010x86 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2010x64 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2012x86 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2012x64 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2013x86 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2013x64 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2015x86 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameMVCPP2015x64 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameSqlClrx64 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameSqlClrx86 -Container $containerName -Destination $localResourcesPath -Context $context 
Get-AzureStorageBlobContent -Blob $blobNameSMOx64 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameSMOx86 -Container $containerName -Destination $localResourcesPath -Context $context  
Get-AzureStorageBlobContent -Blob $blobNameCRx64 -Container $containerName -Destination $localResourcesPath -Context $context     
Get-AzureStorageBlobContent -Blob $blobNameCRx86 -Container $containerName -Destination $localResourcesPath -Context $context  

#Installing Prerequistes
Write-Host "Installing Prerequisites"
Start-Process -FilePath $pathMFCx86 -ArgumentList "/q" -Wait -PassThru
Start-Process -FilePath $pathMVCPP2010x86 -ArgumentList $argumentsEXEFormatOld.Replace("###EXEFILEPATH###", $pathMVCPP2010x86) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2010x64 -ArgumentList $argumentsEXEFormatOld.Replace("###EXEFILEPATH###", $pathMVCPP2010x64) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2012x86 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2012x86) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2012x64 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2012x64) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2013x86 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2013x86) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2013x64 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2013x64) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2015x86 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2015x86) -Wait -PassThru
Start-Process -FilePath $pathMVCPP2015x64 -ArgumentList $argumentsEXEFormat.Replace("###EXEFILEPATH###", $pathMVCPP2015x64) -Wait -PassThru

Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathSqlClrx86) -Wait -PassThru
Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathSqlClrx64) -Wait -PassThru
Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathSMOx86) -Wait -PassThru
Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathSMOx64) -Wait -PassThru
Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathCRx86) -Wait -PassThru
Start-Process -FilePath msiexec.exe -ArgumentList $argumentsMSIFormat.Replace("###MSIFILEPATH###", $pathCRx64) -Wait -PassThru

Write-Host "End configuring the Prerequisites"