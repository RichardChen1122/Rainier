Param(
[string]$TestappName,
[string]$Branch,
[string]$AppConnectionStringName=""
)

$GitPath = "$env:ProgramFiles\Git";
$RepoPath= "$env:SystemDrive\Repo";
$DotnetPath="$env:LOCALAPPDATA\Microsoft\dotnet\";
$GitUrl = "-b release https://github.com/aspnet/Performance.git";
$SitePhysicalPath="$RepoPath\Build\$TestappName\$Branch\netcoreapp1.0\publish\wwwroot"
$ServerName = (Get-WmiObject win32_computersystem).DNSHostName;
$date=$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd"));
$AppName=$TestappName+$Branch;
$SharePath="\\fastshare.file.core.windows.net\aspnet";
#$SharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare";
$ResultSharePath="$SharePath\Reliability\$date\ServerWin$AppName";

function KillProcess
{
    param(
    [string]$Name
    )

    $ret = Get-Process $Name -ErrorAction SilentlyContinue;
    if($ret)
    {
        Stop-Process -processname $Name ;
    }
}

function Cleanup{
    KillProcess $AppName;
    KillProcess "w3wp" ;

    if(Test-Path "$RepoPath\Performance")
    {
        Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clean -xdf" -WorkingDirectory "$RepoPath\Performance" -NoNewWindow -Wait;
        #rmdir -Recurse -Path $RepoPath\Performance\;
        Remove-Item -Recurse -Force $RepoPath\Performance\
    }

    if(Test-Path "$RepoPath\Build\")
    {
        rmdir -Recurse -Path $RepoPath\Build\;
    }

    if(Test-Path "$($env:LOCALAPPDATA)\NUGET\cache\")
    {
        rmdir -Recurse -Path $env:LOCALAPPDATA\NUGET\cache\;
    }

    if(Test-Path "$($env:LOCALAPPDATA)\NUGET\v3-cache\")
    {
        rmdir -Recurse -Path $env:LOCALAPPDATA\NUGET\v3-cache\;
    }
    if(Test-Path "$($env:USERPROFILE)\.dnx\packages\")
    {
        rmdir -Recurse -Path $env:USERPROFILE\.dnx\packages\;
    }
    if(Test-Path "$($env:USERPROFILE)\.nuget\packages\")
    {
        rmdir -Recurse -Path $env:USERPROFILE\.nuget\packages\;
    }
    if(Test-Path "$($env:LOCALAPPDATA)\Microsoft\dotnet")
    {
        rmdir -Recurse -Path $env:LOCALAPPDATA\Microsoft\dotnet\;
    }
    if(Test-Path "$($env:ProgramW6432)\dotnet\")
    {
        rmdir -Recurse -Path $env:ProgramW6432\dotnet\;
    }
}


function AssignUserPermission
{
    $icaclspath = [System.Environment]::GetFolderPath('System')+"\icacls.exe";
    $nugetpath="$env:USERPROFILE\.nuget";
    Start-Process -FilePath $icaclspath -ArgumentList "$DotnetPath /grant IIS_IUSRS:(OI)(CI)F" -Wait;
    Start-Process -FilePath $icaclspath -ArgumentList "$nugetpath /grant IIS_IUSRS:(OI)(CI)F" -Wait;
    Start-Process -FilePath $icaclspath -ArgumentList "$SitePhysicalPath /grant IIS_IUSRS:(OI)(CI)F" -Wait;
}

function CreateSharePath{
    echo "Create Result Share Path";

    if(!(Test-Path $ResultSharePath)){
        mkdir $ResultSharePath;
    }
}

function ChangeConfiguration{

    if($TestappName -eq "MusicStore")
    {
        $FilePath=".\ConnectionString.json";
        $content=( ( Get-Content -Path $FilePath -Raw ) | ConvertFrom-JSON )
        
        $jsonitem=$content.Windows | where {$_.Name -eq $AppConnectionStringName -and $_.Branch -eq $Branch };              
        $ConnectionString=[string]$jsonitem.ConnectionString;
        cmd /c copy /y $RepoPath\Build\$TestappName\$Branch\netcoreapp1.0\publish\web.config $RepoPath\Build\$TestappName\$Branch\netcoreapp1.0\publish\wwwroot\;
        (Get-Content "$SitePhysicalPath\..\config.json").Replace(
        'Server=(localdb)\\MSSQLLocalDB;Database=MusicStore;Trusted_Connection=True;MultipleActiveResultSets=true;Connect Timeout=30;', 
        $ConnectionString) | Set-Content "$SitePhysicalPath\..\config.json";       
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        "dotnet","dotnet.exe") | Set-Content "$SitePhysicalPath\web.config";    
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        ".\MusicStore.dll","..\MusicStore.dll") | Set-Content "$SitePhysicalPath\web.config";     
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        "false","true") | Set-Content "$SitePhysicalPath\web.config";     
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        ".\logs\stdout",".\stdout.log") | Set-Content "$SitePhysicalPath\web.config"; 
        $AFilePath="$env:SystemDrive\Repo\Build\MusicStore\$Branch\netcoreapp1.0\publish\MusicStore.runtimeconfig.json";
        $Acontent=( ( Get-Content -Path $AFilePath -Raw ) -Join "" | ConvertFrom-JSON )
        $add='{
              "System.GC.Server": true
            }';
        $Acontent.runtimeOptions | add-member -Name "configProperties" -Value (ConvertFrom-Json $add) -MemberType NoteProperty;
        ConvertTo-Json -InputObject $Acontent | Set-Content $AFilePath;            
    }
    if($TestappName -eq "StressMvc")
    {
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        'processPath="../StressMvc.exe"','processPath="dotnet.exe" arguments="..\StressMvc.dll" ') | Set-Content "$SitePhysicalPath\web.config";
        (Get-Content "$SitePhysicalPath\web.config").Replace(
        "..\logs\stdout.log",".\stdout.log") | Set-Content "$SitePhysicalPath\web.config";
    }
    
    (Get-Content "$SitePhysicalPath\web.config").Replace(
    ".\stdout.log", "$ResultSharePath\kestrel.log"   ) | Set-Content "$SitePhysicalPath\web.config";  
    (Get-Content "$SitePhysicalPath\web.config").Replace(
    "dotnet.exe","$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe") | Set-Content "$SitePhysicalPath\web.config";
}



function CloneAndBuild{

    #echo $GitPath
    if(!(Test-Path $RepoPath)){
        mkdir $RepoPath;
    }

    Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clone $GitUrl" -WorkingDirectory $RepoPath -NoNewWindow -Wait;
    #(Get-Content "$RepoPath\Performance\nuget.config").Replace(
        #"https://www.myget.org/F/aspnetcirelease/api/v3/index.json","https://dotnet.myget.org/F/aspnet1/api/v3/index.json") | Set-Content "$RepoPath\Performance\nuget.config";
    cd $RepoPath\Performance;
    cmd /c .\build.cmd;
    
    if($ServerName -notmatch "AAPT-PERF")
    {
        AssignUserPermission;
    }
}

function CopyBinaries{

    if(!(Test-Path "$RepoPath\Build\$TestappName\$Branch"))
    {
        mkdir $RepoPath\Build\$TestappName\$Branch;
    }

    cmd /c xcopy /s /i "x:\Build\$TestappName\$Branch" "$RepoPath\Build\$TestappName\$Branch";
    #cmd /c xcopy /s /i "\\aaptperffs\labshare\AspnetCore\AzFileShare\Build\$TestappName\$Branch" "$RepoPath\Build\$TestappName\$Branch";
}

function SetPhysicalPath{
    CreateSharePath;
    cmd /c $env:windir\System32\inetsrv\appcmd.exe set vdir "aspnetcore/" -physicalPath:$SitePhysicalPath
}



Cleanup;
CloneAndBuild;
CopyBinaries;
SetPhysicalPath;
ChangeConfiguration;

