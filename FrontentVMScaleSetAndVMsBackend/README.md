# Buuton to deploy to Azure
<a href="https://azuredeploy.net/?repository=https://github.com/Soruk/AzureRMTemplates/tree/master/FrontentVMScaleSetAndVMsBackend" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

# FrontentVMScaleSetAndVMsBackend
This templates deploys an IaaS enviroment to Azure Public Cloud.
For given resource group, the templates deployes
- 1 VNet with 3 Subnets: Frontend, Backend and Gateway
- 1 VM ScaleSet with 2 VM Windows 2016 Server for Web Frontend
- 1 VM Windows 2016 Server with Sql Server 2016 Backend
- 1 VM Windows 2016 server for Backend application server
- 1 VPN gateway with Local Network Gateway (for S2S scenario) and configruation for P2S scenario

This template is based on Azure Quick Starts Templates
https://github.com/Azure/azure-quickstart-templates