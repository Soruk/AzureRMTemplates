<#
    .SYNOPSIS
        Downloads and configures srv db application.
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

Write-Host "Start configuring the DataBase VM"

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
    $installFolder = "C:\COMAPNY\DBInstall\"
    $dbDataDir = "$installDataDrive`:\COMAPNY\DB\Data\";
    $dbLogDir = "$installDataDrive`:\COMAPNY\DB\Log\";
    $dbBkpDir = "$installDataDrive`:\COMAPNY\DB_Backup\";
    $localImagePath = "$installDataDrive`:\COMAPNY\ImageData\";
    $uncImagePath = "\\$localSrvAppName\ImageData\";


    # Firewall
    Write-Host "Updating Firewall rules"
    netsh advfirewall firewall add rule name="sqlserver" dir=in action=allow protocol=TCP localport=1433

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

    # Install Windows Features
    #Write-Host "Installing Windows Features"
    #Install-WindowsFeature Web-Server,Web-Asp-Net45,Web-Basic-Auth,Web-Windows-Auth,NET-WCF-Services45 -IncludeManagementTools

    # Folders
    Write-Host "Creating folders"
    if (!(Test-Path -Path $localResourcesPath )) {
        New-Item -ItemType Directory $localResourcesPath 
    }
    if (!(Test-Path -Path $dbDataDir )) {
        New-Item -ItemType Directory $dbDataDir 
    }
    if (!(Test-Path -Path $dbLogDir )) {
        New-Item -ItemType Directory $dbLogDir 
    }
    if (!(Test-Path -Path $dbBkpDir )) {
        New-Item -ItemType Directory $dbBkpDir 
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

    # Set up Sql Services
    Write-Host  "Setup SQL Services"
    Set-Service -Name "SQLSERVERAGENT" -StartupType Automatic
    Start-Service -Name "SQLSERVERAGENT"

    # Downloading files from Azure Blob Storage
    Write-Host "Downloading Files From Azure Blob Storage"
    $context = New-AzureStorageContext -StorageAccountName $localStorageAccountName -StorageAccountKey $localStorageAccountKey
    $blobNameMSI = "DatabaseServer.msi"
    $blobNamePS1 = "DatabaseServer.WithUninstall.ps1"
   
    $pathMSI = Join-Path -Path $localResourcesPath $blobNameMSI
    if (Test-Path -Path $pathMSI){
        Remove-Item -Path $pathMSI -Force 
    }
    $pathPS1 = Join-Path -Path $localResourcesPath $blobNamePS1
    if (Test-Path -Path $pathPS1){
        Remove-Item -Path $pathPS1 -Force 
    }

    Get-AzureStorageBlobContent -Blob $blobNameMSI -Container $containerName -Destination $localResourcesPath -Context $context
    Get-AzureStorageBlobContent -Blob $blobNamePS1 -Container $containerName -Destination $localResourcesPath -Context $context

    # Install the DB Setup
    Write-Host "Installing DataBase Server"
    $argumentList = @()
    $argumentList += ("-INSTALLFOLDER", $installFolder)
    $argumentList += ("-INSTANCESQL", "localhost")
    $argumentList += ("-LOGINSQL", "`"`"")
    $argumentList += ("-PASSWORDSQL", "`"`"")
    Invoke-Expression "$pathPS1 $argumentList"

    Write-Host "End configuring the DataBase VM"
}
