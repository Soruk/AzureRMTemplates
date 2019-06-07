# Frontend VM ScaleSet And VMs for Backend
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FFrontendVMScaleSetAndVMsBackend%2Ftemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FFrontendVMScaleSetAndVMsBackend%2Ftemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys an IaaS enviroment to Azure Public Cloud.

For given resource group, the template deployes:
* 1 VNet with 3 Subnets: Frontend, Backend and Gateway
* 1 VM ScaleSet with 2 VM Windows 2019 Server for Web Frontend with Managed Service Identity
* 1 VM Windows 2016 Server with Sql Server 2017 Backend
* 1 VM Windows 2019 server for Backend application server
* 1 Azure Function  with Managed Service Identity
* [1 VPN gateway with Local Network Gateway (for S2S scenario) and configruation for P2S scenario (*only **v1.0** branch*)].

It uses Custom Script Extension to configure the VMs when deploying.
Examples of **PowerShell** scripts are given in the _"scripts"_ subfolder.  
Scripts and installer files are stored in the container of the Azure Blob Storage.

**Remarks**:

The [Azure Availibility Zones](http://aka.ms/azenroll) must be enabled on the subscription, where this template would be deployed.

This template is based on [Azure Quick Starts Templates](https://github.com/Azure/azure-quickstart-templates).