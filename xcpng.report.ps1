#Load DLLs
[reflection.assembly]::loadwithpartialname('system.windows.forms')

$moduleName = "XenServerPSModule";
$Connections = [System.Collections.Generic.List[ConnectionInfo]]@()

if (!(Get-Module -ListAvailable -Name $moduleName)) 
{
   Write-Host "PowerShell Module missing, please install from SDK: " $moduleName
   [system.Windows.Forms.MessageBox]::show("PowerShell Module missing, please install from SDK: " + $moduleName, "XCP-ng PowerShell Module missing")
} 
else 
{
    #OK
    Write-Host "Module found: " $moduleName
    Import-Module XenServerPSModule

    class ConnectionInfo
    {
        [string] $MasterHostUrl;
        [string] $SessionRef;
        [object] $Session;
    }

        
    class ReportItem
    {
        [string]$Uuid;
        [string]$Name;
        [string]$Version;
        [string]$Detected;
        [string]$Up2Date;
        #[ConnectionInfo]$Connection;
        [string]$HostUrl;
    }

    $SelectedObjectNames=@()
    $XenCenterNodeSelected = 0
    $RunFromXcpNgCenter = $true

    #the object info array contains hashmaps, each of which represent a parameter set
    # and describe a target in the XenCenter resource list

    if(($ObjInfoArray -eq "null") -or ($ObjInfoArray.Length -eq 0))
    {
        Write-Host "ObjInfoArray is empty, not launched from XCP-ng Center?"
        $RunFromXcpNgCenter = $false;

        #$XCPnghost = "192.168.1.102"
        #$Username = "root"
        #$Password = "password"

        $XCPnghost = Read-Host -Prompt 'Input your server FQDN/IP'
        $Username = Read-Host -Prompt 'Input your username'
        $Password = Read-Host -Prompt 'Input your server password'


        $connection = [ConnectionInfo]::new()
        $connection.MasterHostUrl = "https://" + $XCPnghost
        $Connections.Add($connection);

        Try 
            {
                $Session = Connect-XenServer -Url https://$XCPnghost -UserName $username -Password $password -NoWarnCertificates -SetDefaultSession
        
            } Catch [XenAPI.Failure] {
                [string]$PoolMaster = $_.Exception.ErrorDescription[1]  
                Write-Host -ForegroundColor Red "$($Pools.$Pool) is slave, Master was identified as $PoolMaster, trying to connect"
                $Pools.Pool = $PoolMaster
                $Session = Connect-XenServer -url "http://$PoolMaster" -UserName $username -Password $password -NoWarnCertificates -SetDefaultSession
            }

        $Sessions = Get-XenSession;
        $session = $Sessions.Where({ $_.URL.Contains($XCPnghost) }, 'First');
        
        if($session -and $con)
        {
            Write-Host "Created a new session for host: " $XCPnghost

            $connection.SessionRef = $session.opaque_ref
            $connection.Session = $session
        }

    }

    foreach($parameterSet in $ObjInfoArray) {
      if ($parameterSet["class"] -eq "blank")
      {
        

        #When the XCP-ng Center node is selected a parameter set is created for each of
        #your connected servers with the class and objUuid keys marked as blank

        #EXAMPLE DATA
        #$ObjInfoArray | Out-GridView -wait

        #url	https://192.168.0.101:443/	
        #sessionRef	OpaqueRef:ae53gb56-6726-7cc6-84f1-63108b9e315e	
        #class	blank	
        #objUuid	blank	
        #url	https://192.168.0.103:443/	
        #sessionRef	OpaqueRef:e8d40c31-1e3d-7b4e-73b4-6c876c17fe55	
        #class	blank	
        #objUuid	blank	

        $connection = [ConnectionInfo]::new()
        $connection.MasterHostUrl = $parameterSet["url"]
        $connection.SessionRef = $parameterSet["sessionRef"]
        $Connections.Add($connection);

        if ($XenCenterNodeSelected)
        {
          continue
        }
        $XenCenterNodeSelected = 1;
        $SelectedObjectNames += "XCP-ng Center"
      }
      elseif ($parameterSet["sessionRef"] -eq "null")
      {
        #When a disconnected server is selected there is no session information,
        #we get null for everything except class
        $SelectedObjectNames += "a disconnected server"
      }
      else
      {
        Connect-XenServer -url $parameterSet["url"] -opaqueref $parameterSet["sessionRef"]
        #Use $class to determine which server objects to get
        #-Uuid allows us to filter the results to just include the selected object
        $exp = "Get-Xen{0} -Uuid {1}" -f $parameterSet["class"], $parameterSet["objUuid"]
        $obj = Invoke-Expression $exp
        $SelectedObjectNames += $obj.name_label;

        $connection = [ConnectionInfo]::new()
        $connection.MasterHostUrl = $parameterSet["url"]
        $connection.SessionRef = $parameterSet["sessionRef"]
        $Connections.Add($connection);
      }
    }

    $InfoString = "Launched from {0}." -f ($SelectedObjectNames -join ', ')

    #show an alert dialog with the text
    #[system.Windows.Forms.MessageBox]::show($InfoString, "XCP-ng")


    $Report = [System.Collections.Generic.List[ReportItem]]@()


    # Create Sessions

    foreach($con in $Connections)
    {
        #[system.Windows.Forms.MessageBox]::show($con.MasterHostUrl, "XCP-ng Connection")
    
        #Check if already there is already a session to that host
        $Sessions = Get-XenSession;
        $session = $Sessions.Where({ $_.URL.Contains($con.MasterHostUrl) }, 'First');


        if(!$session)
        {
            Try 
            {
                #Connection.session = new Session(Connection.MasterHostUrl, Connection.SessionRef);
                #$Session = [XenAPI.Session]::new($con.MasterHostUrl, $con.SessionRef)
                #$Session = Connect-XenServer -Url https://$XCPnghost -UserName $username -Password $password -NoWarnCertificates -SetDefaultSession

                $Session = Connect-XenServer -url $con.MasterHostUrl -opaqueref $con.SessionRef]
        
            } Catch [XenAPI.Failure] {
                Write-Host -ForegroundColor Red "Error to connect"
            }

            $Sessions = Get-XenSession;
            $session = $Sessions.Where({ $_.URL.Contains($XCPnghost) }, 'First');
            

            if($session -and $con)
            {
                Write-Host "Created a new session for host: " $con.MasterHostUrl

                $con.SessionRef = $session.opaque_ref
                $con.Session = $session
            }
            else
            {
                 Write-Host "Failed to create a new session for host: " $XCPnghost
            }
         }
         else
         {
            Write-Host "There is already a session for that host"

            $con.SessionRef = $session.opaque_ref
            $con.Session = $s
         }


          $VMs = Get-XenVM | Where {$_.is_a_template -eq $False -and $_.is_a_snapshot -eq $False -and $_.domid -ne 0}

        foreach ($vm in $VMs)
        {
            $reportItem = [ReportItem]::new()

            #$reportItem.Connection = $con;

            $reportItem.HostUrl = $con.MasterHostUrl

            Write-Host $vm.uuid
            $reportItem.Uuid = $vm.uuid

            Write-Host $vm.name_label
            $reportItem.Name = $vm.name_label

            
            $metrics = Get-XenVMGuestMetrics -Ref $vm.guest_metrics.opaque_ref

            Write-Host "PV_drivers_detected: " $metrics.PV_drivers_detected
            $reportItem.Detected = $metrics.PV_drivers_detected
            Write-Host "PV_drivers_up_to_date: "$metrics.PV_drivers_up_to_date
            $reportItem.Up2Date = $metrics.PV_drivers_up_to_date

            $versionString = [string]::Format("{0}.{1}.{2}.{3}", $metrics.PV_drivers_version["major"], $metrics.PV_drivers_version["minor"], $metrics.PV_drivers_version["micro"], $metrics.PV_drivers_version["build"]);

            Write-Host "PV_drivers_version: " $versionString
            $reportItem.Version = $versionString

            $Report.Add($reportItem);

        }


    }


    #$Sessions = Get-XenSession;
    #foreach($s in $Sessions)
    #{
        #[system.Windows.Forms.MessageBox]::show($s.Url, "XCP-ng Sessions")
    #}



    $Report | Out-GridView -Wait

    #Disconnect Sessions
    if(!$RunFromXcpNgCenter) { Get-XenSession | Disconnect-XenServer }
}



