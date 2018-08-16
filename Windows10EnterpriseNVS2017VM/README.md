# Windows 10 Enterpirse N with Visual Studio 2017
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FWindows10EnterpriseNVS2017VM%2Ftemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FWindows10EnterpriseNVS2017VM%2Ftemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys an VM with Windows 10 Enterprise N edition with Visual Studio.

For given resource group, the template deployes:
* 1 VNet with 2 Subnets: default and vm-subnet.
* 1 Storage account for diagnostics data.
* 1 Public IP address.
* 1 VM with Windows 10 Enterprise N and Visual Studio 2017 containing OS Disk and Data Disk.
* 1 Network security group allowing RDP connection for the NIC card.

It is recommanded to deploy this template to the region where there is a DevLabs to automatically shutdown VM at given time.

**Remarks**:

This templates works on the Azure subscription offered by MPN / Visual Studio subscription.
