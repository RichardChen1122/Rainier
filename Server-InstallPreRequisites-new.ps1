Param(
[string]$FileShareUser="fastshare",
[string]$FileSharePassword="05oBpnhrbJVwZt6LsHUqXaqiyMA84ba3lenO2Ou1ShJq/Bhg4UbDceZ5R634ffa4t+Te5SJ38cmEoWhRzqu/cg=="
)

$GitPath = "$env:ProgramFiles\Git"
$RepoPath= "$env:SystemDrive\Repo";
$BuildPath="$env:SystemDrive\Repo\Build";
$DotnetPath="$env:LOCALAPPDATA\Microsoft\dotnet\";
$ServerName = (Get-WmiObject win32_computersystem).DNSHostName;



if($ServerName -notmatch "AAPT-PERF"){
    $SharePath="\\fastshare.file.core.windows.net\aspnet";
}
else{
    $SharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare";
    cmd \c net use \\aaptperffs\labshare\AspnetCore\AzFileShare;
}

function CreateAppPoolAndSite{

    echo "Create Application Pool and site";
    if($ServerName -notmatch "AAPT-PERF"){
    cmd /c $env:windir\System32\inetsrv\appcmd.exe add apppool /name:aspnetcore /managedRuntimeVersion:"" /queueLength:10000 /enableConfigurationOverride:true /processModel.identitytype:SpecificUser /processModel.userName:$FileShareUser /processModel.password:$FileSharePassword
    }
    else{
        cmd /c $env:windir\System32\inetsrv\appcmd.exe add apppool /name:aspnetcore /managedRuntimeVersion:"" /queueLength:10000 /enableConfigurationOverride:true
    }
    cmd /c $env:windir\System32\inetsrv\appcmd.exe add site /name:aspnetcore /bindings:http/*:8080:$ServerName /applicationDefaults.applicationPool:"aspnetcore" /physicalPath:"C:\"
    cmd /c $env:windir\System32\inetsrv\appcmd.exe set config /section:system.webserver/serverRuntime /appConcurrentRequestLimit:25000;
}



function CreateUser
{
    if($ServerName -notmatch "AAPT-PERF")
    {
    echo "Create IIS User";
    #Add User 
    #cmd /c net user $FileShareUser /delete
    cmd /c net user $FileShareUser $FileSharePassword /add /y
    cmd /c net localgroup IIS_IUSRS $FileShareUser /add
    }
}


function InstallPreReqs{

    # Install Git
    if(!(Test-Path $GitPath))
    {
         Start-Process -FilePath .\Git-2.7.4-64-bit.exe -ArgumentList "/silent /norestart" -NoNewWindow -wait;
    }

    # Install Core Module
    $AspnetCoreMoudle = Get-WmiObject -Class Win32_Product | where-object{
            $_.Name -match "Core Module";
        }

    msiexec /i aspnetcoremodule_x64_en.msi  /quiet


    #install IIS

        $pkgmgrpath = [System.Environment]::GetFolderPath('System')+"\pkgmgr.exe";
        Start-Process -FilePath $pkgmgrpath -ArgumentList "/l:log.etw /iu:IIS-WebServerRole;WAS-WindowsActivationService;WAS-ProcessModel;WAS-NetFxEnvironment;WAS-ConfigurationAPI;IIS-ApplicationDevelopment;IIS-ASPNET;IIS-DefaultDocument;IIS-NetFxExtensibility;IIS-ISAPIExtensions;IIS-ISAPIFilter;IIS-RequestFiltering;IIS-Metabase;IIS-WMICompatibility;IIS-LegacyScripts;IIS-IIS6ManagementCompatibility;IIS-WebServerManagementTools;IIS-HttpTracing" -Wait


    CreateUser;

    CreateAppPoolAndSite;

    if(!(Test-Path $RepoPath))
    {
        mkdir $RepoPath;
    }
    if(!(Test-Path $BuildPath))
    {
        mkdir $BuildPath
    }

    AssignUserPermission;
}

function AssignUserPermission
{
    $icaclspath = [System.Environment]::GetFolderPath('System')+"\icacls.exe";
    Start-Process -FilePath $icaclspath -ArgumentList "$BuildPath /grant IIS_IUSRS:(OI)(CI)F" -Wait;
}

InstallPreReqs;

