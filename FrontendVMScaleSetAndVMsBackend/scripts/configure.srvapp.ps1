<#
    .SYNOPSIS
        Downloads and configures srv app application.
#>

Param (   
    [ValidateSet("dev", "test", "prod")]
    [string]$environmentType = "dev",
    [string]$srvDbName,
    [string]$srvAppName,
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$vmAdminUsername,
    [string]$vmAdminPassword 
)

Write-Host "Start configuring the Application VM"

$password = ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\$vmAdminUsername", $password)
 
Write-Host "Entering Custom Script Extension..."
Write-Host "Output Global $environmentType, $srvDbName, $srvAppName,  $storageAccountName, $storageAccountKey"

$globalArgumentList = @(
    $PSScriptRoot,
    $environmentType,
    $srvDbName,
    $srvAppName,
    $storageAccountName,
    $storageAccountKey,
    $vmAdminUsername,
    $vmAdminPassword
)
Invoke-Command -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList $globalArgumentList -ScriptBlock {    
    Param 
    (
        [string]$localWorkingDir,
        [string]$localEnvironmentType,
        [string]$localSrvDbName,
        [string]$localSrvAppName,
        [string]$localStorageAccountName,
        [string]$localStorageAccountKey,
        [string]$localVmAdminUsername,
        [string]$localVmAdminPassword
    )  

    Write-Host "Output Loacal $localWorkingDir, $localEnvironmentType, $localSrvDbName, $localSrvAppName,  $localStorageAccountName, $localStorageAccountKey"
    
    #################################
    # Elevated custom scripts go here 
    #################################
    Write-Host "Entering Elevated Custom Script Commands..."
    # Constants
    $localResourcesPath = "C:\INSTALL"
    $containerName = $localEnvironmentType
    $newDvdDriveLetter = "Z:";
    $installDataDrive = "E"
    $installFolder = "C:\COMPANY\APPSRV_CTRL\"
    $localImagePath = "$installDataDrive`:\COMPANY\ImageData\";
    $uncImageName = "ImageData";
    $localWorkingPath = "$installDataDrive`:\COMPANY\WorkingDirectory\";
    $uncWorkingName = "WorkingDirectory";

    # Firewall
    Write-Host "Updating Firewall rules"
    netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

    # Install Windows Features
    Write-Host "Installing Windows Features"
    Install-WindowsFeature Web-Server, Web-Asp-Net45, Web-Basic-Auth, Web-Windows-Auth, NET-WCF-Services45 -IncludeManagementTools
 
    # Change CD-ROM drive letter
    $dvdDrive = Get-WmiObject -Class Win32_Volume -Filter "DriveType=5"
    # Check if CD/DVD Drive is Available
    if ($dvdDrive -ne $null) {
        # Get Current Drive Letter for CD/DVD Drive
        $oldDvdDriveLetter = $dvdDrive | Select-Object -ExpandProperty DriveLetter
        Write-Output "Current CD/DVD Drive Letter is $oldDvdDriveLetter"
 
        # Confirm New Drive Letter is NOT used
        if (-not (Test-Path -Path $newDvdDriveLetter)) {
            # Change CD/DVD Drive Letter
            $dvdDrive | Set-WmiInstance -Arguments @{DriveLetter = "$newDvdDriveLetter"}
            Write-Output "Updated CD/DVD Drive Letter as $newDvdDriveLetter"
        }
        else {
            Write-Output "Error: Drive Letter $newDvdDriveLetter Already In Use"
        }
    }
    else {
        Write-Output "Error: No CD/DVD Drive Available !"
    }

    # Initialize raw disks
    Write-Host "Initialize raw disk"
    Get-Disk |
        Where-Object partitionstyle -eq 'raw' | #already initilzer
        Initialize-Disk -PartitionStyle MBR -PassThru |
        #Where-Object Number -eq 2 | # the data disk is the 3rd disk, after OS end TEMP
    New-Partition -AssignDriveLetter -UseMaximumSize |
        #New-Partition -DriveLetter "$installDataDrive" -UseMaximumSize | # want to have give drive letter
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -Confirm:$false


    # Folders
    Write-Host "Creating folders"
    if (!(Test-Path -Path $localResourcesPath )) {
        New-Item -ItemType Directory $localResourcesPath 
    }
    if (!(Test-Path -Path $localImagePath )) {
        New-Item -ItemType Directory $localImagePath 
    }
    if (!(Test-Path -Path $localWorkingPath )) {
        New-Item -ItemType Directory $localWorkingPath 
    }

    if (!(Get-SMBShare -Name $uncImageName)) {
        New-SMBShare –Name $uncImageName –Path $localImagePath `
            –ContinuouslyAvailable `
            –FullAccess "$env:USERDOMAIN\$localVmAdminUsername" `
            -ReadAccess "Everyone"
    }

    if (!(Get-SMBShare -Name $uncWorkingName)) {
        New-SMBShare –Name $uncWorkingName –Path $localWorkingDir `
            –ContinuouslyAvailable `
            –FullAccess "$env:USERDOMAIN\$localVmAdminUsername" `
            -ReadAccess "Everyone"
    }

    # PS Providres
    Write-Host  "Installing PS Providers"
    if (!(Get-PackageProvider -ListAvailable -Name Nuget)) {
        Install-PackageProvider Nuget -Force
    }

    # PS Modules
    Write-Host  "Installing PS Modules"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (!(Get-Module -ListAvailable -Name AzureRM)) {
        Install-Module AzureRM -Force
    }

    # Downloading files from Azure Blob Storage
    Write-Host "Downloading Files From Awure Blob Storage"
    $context = New-AzureStorageContext -StorageAccountName $localStorageAccountName -StorageAccountKey $localStorageAccountKey
    $blobNamePrerequisitesPS1 = "configure.prerequisites.ps1"
    $blobNameMSI = "ApplicationServer.msi"
    $blobNamePS1 = "ApplicationServer.WithUninstall.ps1"

    $pathPrerequisitesPS1 = Join-Path -Path $localResourcesPath $blobNamePrerequisitesPS1
    if (Test-Path -Path $pathPrerequisitesPS1){
        Remove-Item -Path $pathPrerequisitesPS1 -Force 
    } 
    $pathMSI = Join-Path -Path $localResourcesPath $blobNameMSI
    if (Test-Path -Path $pathMSI){
        Remove-Item -Path $pathMSI -Force 
    }
    $pathPS1 = Join-Path -Path $localResourcesPath $blobNamePS1
    if (Test-Path -Path $pathPS1){
        Remove-Item -Path $pathPS1 -Force 
    }

    Get-AzureStorageBlobContent -Blob $blobNamePrerequisitesPS1 -Container $containerName -Destination $localResourcesPath -Context $context 
    Get-AzureStorageBlobContent -Blob $blobNameMSI -Container $containerName -Destination $localResourcesPath -Context $context  
    Get-AzureStorageBlobContent -Blob $blobNamePS1 -Container $containerName -Destination $localResourcesPath -Context $context  
   
    # Installing prerequisites
    Write-Host "Installing Prerequisites"
    $argumentList = @()
    $argumentList += ("-containerName", "$containerName-req")
    $argumentList += ("-storageAccountName", $localStorageAccountName)
    $argumentList += ("-storageAccountKey", $localStorageAccountKey)
    $argumentList += ("-localResourcesPath", $localResourcesPath)
            
    Invoke-Expression "$pathPrerequisitesPS1 $argumentList"

    # Install the App Setup    
    Write-Host "Installing Application Server"
    $argumentList = @()
    $argumentList += ("-INSTALLFOLDER", $installFolder)
    $argumentList += ("-INSTANCESQL", $localSrvDbName)
    $argumentList += ("-ADDLOCAL", "`"Comma,Separated,Features`"")
    $argumentList += ("-WORKINGDIRECTORY", $localWorkingPath)
    
    Invoke-Expression "$pathPS1 $argumentList"

    Write-Host "End configuring the Application VM"
}