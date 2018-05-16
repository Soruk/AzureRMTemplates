<#
    .SYNOPSIS
        Downloads and configures srv app application.
#>

Param (   
    [ValidateSet("dev", "test", "prod")]
    [string]$environmentType = "dev",
    [int]$environmentNumber,
    [string]$srvDbName,
    [string]$srvAppName,
    [string]$storageAccountName,
    [string]$storageAccountKey,
    [string]$vmAdminUsername,
    [string]$vmAdminPassword 
)
$logFile=$script:MyInvocation.MyCommand.Path + ".txt"
if (Test-Path -Path $logFile -ErrorAction SilentlyContinue) {
    Remove-Item -Path $logFile -Force -Recurse
} 
Write-Output "Start configuring the Application VM" | Out-File $logFile

$password = ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\$vmAdminUsername", $password)
 
Write-Output "Entering Custom Script Extension..." | Out-File $logFile -Append
Write-Output "Output Global $environmentType, $environmentNumber, $srvDbName, $srvAppName,  $storageAccountName, $storageAccountKey" | Out-File $logFile -Append

$globalArgumentList = @(
    $PSScriptRoot,
    $logFile,
    $environmentType,
    $environmentNumber,
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
        [string]$localLogFile,
        [string]$localEnvironmentType,
        [int]$localEnvironmentNumber,
        [string]$localSrvDbName,
        [string]$localSrvAppName,
        [string]$localStorageAccountName,
        [string]$localStorageAccountKey,
        [string]$localVmAdminUsername,
        [string]$localVmAdminPassword
    )  

    Write-Output "Output Loacal $localWorkingDir, $localLogFile, $localEnvironmentType, $localEnvironmentNumber, $localSrvDbName, $localSrvAppName,  $localStorageAccountName, $localStorageAccountKey" | Out-File $localLogFile -Append
    
    #################################
    # Elevated custom scripts go here 
    #################################
    Write-Output "Entering Elevated Custom Script Commands..."
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
    Write-Output "Updating Firewall rules" | Out-File $localLogFile -Append
    netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

    # Install Windows Features
    Write-Output "Installing Windows Features" | Out-File $localLogFile -Append
    Install-WindowsFeature Web-Server, Web-Asp-Net45, Web-Basic-Auth, Web-Windows-Auth, NET-WCF-Services45 -IncludeManagementTools
 
    # Change CD-ROM drive letter
    $dvdDrive = Get-WmiObject -Class Win32_Volume -Filter "DriveType=5"
    # Check if CD/DVD Drive is Available
    if ($dvdDrive -ne $null) {
        # Get Current Drive Letter for CD/DVD Drive
        $oldDvdDriveLetter = $dvdDrive | Select-Object -ExpandProperty DriveLetter
        Write-Output "Current CD/DVD Drive Letter is $oldDvdDriveLetter" | Out-File $localLogFile -Append
 
        # Confirm New Drive Letter is NOT used
        if (-not (Test-Path -Path $newDvdDriveLetter)) {
            # Change CD/DVD Drive Letter
            $dvdDrive | Set-WmiInstance -Arguments @{DriveLetter = "$newDvdDriveLetter"}
            Write-Output "Updated CD/DVD Drive Letter as $newDvdDriveLetter" | Out-File $localLogFile -Append
        }
        else {
            Write-Output "Error: Drive Letter $newDvdDriveLetter Already In Use" | Out-File $localLogFile -Append
        }
    }
    else {
        Write-Output "Error: No CD/DVD Drive Available !" | Out-File $localLogFile -Append
    }

    # Initialize raw disks
    Write-Output "Initialize raw disk" | Out-File $localLogFile -Append
    Get-Disk |
        Where-Object partitionstyle -eq 'raw' | #already initilzer
        Initialize-Disk -PartitionStyle MBR -PassThru |
        #Where-Object Number -eq 2 | # the data disk is the 3rd disk, after OS end TEMP
    New-Partition -AssignDriveLetter -UseMaximumSize |
        #New-Partition -DriveLetter "$installDataDrive" -UseMaximumSize | # want to have give drive letter
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -Confirm:$false


    # Folders
    Write-Output "Creating folders" | Out-File $localLogFile -Append
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
    Write-Output  "Installing PS Providers" | Out-File $localLogFile -Append
    if (!(Get-PackageProvider -ListAvailable -Name Nuget)) {
        Install-PackageProvider Nuget -Force
    }

    # PS Modules
    Write-Output  "Installing PS Modules" | Out-File $localLogFile -Append
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (!(Get-Module -ListAvailable -Name AzureRM)) {
        Install-Module AzureRM -Force
    }

    # Downloading files from Azure Blob Storage
    Write-Output "Downloading Files From Azure Blob Storage" | Out-File $localLogFile -Append
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
    Write-Output "Installing Prerequisites" | Out-File $localLogFile -Append
    $argumentList = @()
    $argumentList += ("-containerName", "$containerName-req")
    $argumentList += ("-storageAccountName", $localStorageAccountName)
    $argumentList += ("-storageAccountKey", $localStorageAccountKey)
    $argumentList += ("-localResourcesPath", $localResourcesPath)            
    Invoke-Expression "$pathPrerequisitesPS1 $argumentList"

    # Install the App Setup    
    Write-Output "Installing Application Server" | Out-File $localLogFile -Append
    $argumentList = @()
    $argumentList += ("-INSTALLFOLDER", $installFolder)
    $argumentList += ("-INSTANCESQL", $localSrvDbName)
    $argumentList += ("-ADDLOCAL", "`"Comma,Separated,Features`"")
    $argumentList += ("-WORKINGDIRECTORY", $localWorkingPath)    
    Invoke-Expression "$pathPS1 $argumentList"

    Write-Output "End configuring the Application VM" | Out-File $localLogFile -Append
}