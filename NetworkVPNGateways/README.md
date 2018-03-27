# Frontend VM ScaleSet And VMs for Backend
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FNetworkVPNGateways%2Ftemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSoruk%2FAzureRMTemplates%2Fmaster%2FNetworkVPNGateways%2Ftemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys an IaaS Network enviroment to Azure Public Cloud.

For given resource group, the template deployes:
* 2 VNet with 2 Subnets each: Default and Gateway
* 1 VPN Routed Based gateway with Local Network Gateway (for S2S scenario) and configruation for P2S scenario
* 1 VPN Policy Bases gateway with Local Newwork Gateway (for S2S scenario)

**Remarks**:

The [Azure Availibility Zones](http://aka.ms/azenroll) must be enabled on the subscription, where this template would be deployed.
