# xcpng.report
XCP-ng Center PowerShell Plugin to generate a report about installed Guest Tool Versions.

### WARNING
This project is still in its very early stage of development. There are bugs and missing features.
Should be tested with test environments before used in production environments!

I take no responsibility or liability for any code and files available here. By using any of the files available in this repository, you understand that you are agreeing to use at your own risk.


### Setup

Requires the PowerShell Module from the CitrixHypervisor-SDK: "XenServerPSModule".

The "SDK (Software Development Kit) 8.2.1" can be downloaded for here:
https://www.citrix.com/downloads/citrix-hypervisor/product-software/hypervisor-82-express-edition.html


Copy the folder "XenServerPSModule" to one of your PowerShell Module Directories:

```
[System Global]
%windir%\System32\WindowsPowerShell\v1.0\Modules\
```

```
[User Profile]
%USERPROFILE%\Documents\WindowsPowerShell\Modules\
```
Must be extracted and copied manually currently.
Copy to plugins directory in XCP-ng Center installation path.

Example:
```
C:\Program Files (x86)\XCP-ng Center\Plugins\xcp-ng.org\xcpng.report\xcpng.report.ps1
C:\Program Files (x86)\XCP-ng Center\Plugins\xcp-ng.org\xcpng.report\xcpng.report.xcplugin.xml
```

Might require to install Dotnet Framework.


### Launch

From within XCP-ng Center --> View --> Guest Tools Report (PS)

![xcp-ng-report](https://user-images.githubusercontent.com/1071741/133763136-0f1edb2d-a40b-44f6-82cf-ea7ccb2dbdcf.png)

