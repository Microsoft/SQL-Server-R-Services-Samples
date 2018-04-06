<#
.SYNOPSIS  
    The script allows configuring ML services on SQL Server
 
.DESCRIPTION  
     The script allows configuring ML services on SQL Server
     Assumption is that SQL server is already installed with ML services.
     You should copy this script on the SQL server machine and run it in admin mode.
     This script does the following
        1. Enable external script execution on SQL Server
        2. Restart SQL server and related services
        3. Ensure that launchpad service is running and it set to automatic mode
        4. Tries to create login for SQLRUserGroup if not present already.
.LINK  
    Install link https://docs.microsoft.com/en-us/sql/advanced-analytics/install/sql-machine-learning-services-windows-install
.EXAMPLE  
    Install on local server
    ConfigureMachineLearning.ps1 
    
    Install on specific instance 
    ConfigureMachineLearning.ps1 -Instance "Instance1"
    
    Install using SQL authentication (e.g. sa account)
    ConfigureMachineLearning.ps1 -Instance "Instance1" -UserName "sa" -Password "{YourPassword}"

.FUNCTIONALITY  
   This script does the following
        1. Enable external script execution on SQL Server
        2. Restart SQL server and related services
        3. Ensure that launchpad service is running and it set to automatic mode
        4. Tries to create login for SQLRUserGroup if not present already.
#>
param(
        [Parameter(Position=0, Mandatory=$false)]
        [string]$Server = $env:computername,
        
        [Parameter(Position=1, Mandatory=$false)]
        [string]$Instance,
        
        [Parameter(Position=2, Mandatory=$false)]
        [string]$UserName,
        
        [Parameter(Position=3, Mandatory=$false)]
        [string]$Password
    )

[System.Collections.ArrayList]$DependentServices = @()
function GetDependentServices ($ServiceInput) {
    
    If ($ServiceInput.DependentServices.Count -gt 0) {
        ForEach ($DepService in $ServiceInput.DependentServices) {
            If ($DepService.Status -eq "Running") {
                $CurrentService = Get-Service -Name $DepService.Name
                GetDependentServices $CurrentService                
            }
        }
    }
    
    if ($DependentServices.Contains($ServiceInput.Name) -eq $false) {
        Write-Host "Service to stop $($ServiceInput.Name)"
        $DependentServices.Add($ServiceInput.Name)
    }
    
}

function RunSqlQuery {
param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$ServerInstance,
        
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Query,
        
        [Parameter(Position=2, Mandatory=$false)]
        [string]$UserName,
        
        [Parameter(Position=3, Mandatory=$false)]
        [string]$Password
    )

    Write-Host ("Running folllowing SQL script on $ServerInstance")
    Write-Host ($SQLScript)

    if ($UserName) {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $Query -Username $UserName -Password $Password
    }
    else {
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $Query
    }


}


function SetMachineLearningService {
param(
        [Parameter(Position=0, Mandatory=$false)]
        [string]$Server = $env:computername,
        
        [Parameter(Position=1, Mandatory=$false)]
        [string]$Instance,
        
        [Parameter(Position=2, Mandatory=$false)]
        [string]$UserName,
        
        [Parameter(Position=3, Mandatory=$false)]
        [string]$Password
    )

try 
{
    $ServerInstance = $Server

    If (![string]::IsNullOrWhitespace($Instance)){
        $ServerInstance += "\$Instance";
    } 

    
    Write-Host ("**** Enabling ML services **************")
    Write-Host ("")
    Write-Host ("Server: $ServerInstance")
    Write-Host ("")
    
    Write-Host ("Current value of external service")
    $sqlQuery = "EXEC sp_configure  'external scripts enabled'"

    RunSqlQuery -ServerInstance $ServerInstance -Query $sqlQuery -Username $UserName -Password $Password


    Write-Host ("Configuring SQL to allow running of External Scripts")

    $sqlQuery =@"
EXEC sp_configure  'external scripts enabled', 1
GO
RECONFIGURE WITH OVERRIDE
GO
"@
    RunSqlQuery -ServerInstance $ServerInstance -Query $sqlQuery -Username $UserName -Password $Password
    
    Write-Host ("SQL Server Configured to allow running of External Scripts")


    Write-Host ("Restarting SQL Server and dependent services")

    $serviceName = "MSSQLSERVER"
    If (![string]::IsNullOrWhitespace($Instance)){
        $serviceName = "MSSQL$" + $Instance
    }

    $launchPadService = "MSSQLLaunchpad"
    If (![string]::IsNullOrWhitespace($Instance)){
        $launchPadService = "MSSQLLaunchpad$" + $Instance
    }

    # Get the main service
    $Service = Get-Service -Name $serviceName

    # Get dependancies and stop order
    GetDependentServices -ServiceInput $Service


    Write-Host "-------------------------------------------"
    Write-Host "Stopping Services"
    Write-Host "-------------------------------------------"
    foreach ($ServiceToStop in $DependentServices) {
        Write-Host "Stop Service $ServiceToStop"
        Stop-Service $ServiceToStop -Verbose #-Force
    }
    Write-Host "-------------------------------------------"
    Write-Host "Starting Services"
    Write-Host "-------------------------------------------"
    # Reverse stop order to get start order
    $DependentServices.Reverse()

    foreach ($ServiceToRestart in $DependentServices) {
        Write-Host "Start Service $ServiceToRestart"
        Start-Service $ServiceToRestart -Verbose
    }
    Write-Host "-------------------------------------------"
    Write-Host "Restart of services completed"
    Write-Host "-------------------------------------------"

    # ************ Ensure that launchpad service is running. *************
    $Service = Get-Service -Name $launchPadService
    if ($Service[0].Status -eq "Stopped") {
        Write-Host "Launchpad service $launchPadService is stopped. Starting the service "
        Start-Service $Service[0] -Verbose
    }
    
    if ($Service[0].StartType -eq "Manual") {
        Write-Host "Updating Launchpad service $launchPadService to run automatic"
        Set-Service -Name $launchPadService -StartupType automatic -Verbose
    }
    

    Write-Host ("Checking value of external script")
    $sqlQuery = "EXEC sp_configure  'external scripts enabled'"
    RunSqlQuery -ServerInstance $ServerInstance -Query $sqlQuery -Username $UserName -Password $Password

    Write-Host ("**** Please double check that run_value is 1 **************")
    Write-Host ("**** Enabled ML services on $ServerInstance **************")

    # *************** Miscellaneous steps ******************
    # *************** Create login for SQLRUserGroup if not exists for implied auth ******************
    
    try {
      Write-Host ("**** Creating login for SQLRUserGroup **************")
      $sqlQuery =@"
IF NOT EXISTS (SELECT LoginName FROM Master.dbo.syslogins WHERE NAME LIKE  '%\SQLRUserGroup')
BEGIN
	CREATE LOGIN [$Server\SQLRUserGroup] FROM WINDOWS WITH DEFAULT_DATABASE=[MASTER], DEFAULT_LANGUAGE=[US_ENGLISH]
END
"@
        RunSqlQuery -ServerInstance $ServerInstance -Query $sqlQuery -Username $UserName -Password $Password
    }
    catch [System.Exception]
    {
        Write-Error "Creating login for SQLRUserGroup failed.  ";
    }

    }

    catch [System.Exception]
    {
        Write-Error "Error has occurred.";
        $Error | Format-List | Out-String | Write-Error;
    }
}

SetMachineLearningService -Server $Server -Instance $Instance -UserName $UserName -Password $Password

#SetMachineLearningService -Instance "Instance1"
#SetMachineLearningService -Instance "Instance1"
