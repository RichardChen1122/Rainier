Param(
[bool]$ServerGC=$true
)

$RepoPath= "~/Peformance/";
$DotnetPath="/home/asplab/.dotnet/dotnet";
$Client="aapt-perf-045l";
$Server="aapt-perf-044l";
$ServerIP="10.194.216.1";
$Port5000=":5000";
$Port8080=":8080";
$GCMode="";
$date=$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd"));
$SharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare";
$ResultSharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare\Performance\$date";

if($ServerGC)
{
    $GCMode="ServerGC";
}
else
{
    $GCMode="WorkStationGC";
}

function RunRemotelyOnServer{
    Param(
    [string]$Command
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Server" -NoNewWindow -wait -RedirectStandardError "$ResultSharePath\error.log";;
}

function RunRemotelyOnServerNoWait{
    Param(
    [string]$Command
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Server" -NoNewWindow -RedirectStandardError "$ResultSharePath\error.log";;
}

function RunRemotelyOnServerOutput{
    Param(
    [string]$Command,
    [string]$OutputPath
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Server" -NoNewWindow -wait -RedirectStandardOutput $OutputPath -RedirectStandardError "$ResultSharePath\error.log";;
}

function RunRemotelyOnServerOutputNoWait{
    Param(
    [string]$Command,
    [string]$OutputPath
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Server" -NoNewWindow -RedirectStandardOutput $OutputPath -RedirectStandardError "$ResultSharePath\error.log";;
}

function RunRemotelyOnClient{
    Param(
    [string]$Command
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Client" -NoNewWindow -wait -RedirectStandardError "$ResultSharePath\error.log";;
}

function RunRemotelyOnClientOutput{
    Param(
    [string]$Command,
    [string]$OutputPath
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Client" -NoNewWindow -wait -RedirectStandardOutput $OutputPath -RedirectStandardError "$ResultSharePath\error.log";
}

function RunRemotelyOnClientOutputNoWait{
    Param(
    [string]$Command,
    [string]$OutputPath
    )
    $a=Get-Date;
    $random=$a.Hour.ToString()+$a.Minute.ToString()+$a.Second.ToString()+$a.Millisecond.ToString();
    New-Item C:\temp\$random.txt -ItemType file -Value $Command;
    Start-Process -FilePath "plink.exe" -ArgumentList "-ssh -l asplab -pw iis6!dfu -m C:\temp\$random.txt $Client" -NoNewWindow -RedirectStandardOutput $OutputPath -RedirectStandardError "$ResultSharePath\error.log";;
}

function KillProcess
{
    param(
    [string]$Name
    )

    RunRemotelyOnServer "pkill $Name";
}

function Cleanup{
    KillProcess "dotnet";
    KillProcess "nginx";

    RunRemotelyOnServer "rm -rf ~/.nuget";
    RunRemotelyOnServer "rm -rf ~/.dotnet";
    RunRemotelyOnServer "rm -rf ~/Performance";
    RunRemotelyOnServer "rm -rf ~/musicStore";

}


function CloneAndBuild{
    RunRemotelyOnServer "git clone -b dev https://github.com/aspnet/Performance.git";
    RunRemotelyOnServer "git clone -b dev https://github.com/aspnet/musicStore/";

    RunRemotelyOnServer "~/Performance/build.sh clean";
}

function RunScenarios{


    RunScenarioNginx "HelloWorldMvc";

    RunScenarioNginx "BasicKestrel";
    
    RunScenarioNginx "MusicStore";

    RunScenarioKestrel "HelloWorldMvc";

    RunScenarioKestrel "BasicKestrel";
    
    RunScenarioKestrel "MusicStore";
}

function RunScenarioNginx{
    param(
    [string]$TestappName
    )
    if($TestappName -ne "MusicStore")
    {
        $SitePhysicalPath = "~/Performance/testapp/$TestappName/bin/release/netcoreapp1.0/publish";
    }
    else{
        $SitePhysicalPath = "~/musicStore/src/MusicStore/bin/release/netcoreapp1.0/publish";
    }
    Write-Host "nginx" + $TestappName -foregroundcolor red -backgroundcolor yellow
    [string]$PathofOutput= $ResultSharePath + "\" + "LinuxNginx" + $TestappName;
    if(!(Test-Path "$PathofOutput")){
        mkdir "$PathofOutput";
    }

    RunRemotelyOnServerNoWait "$DotnetPath $SitePhysicalPath/$TestappName.dll";
    Start-Sleep -s 5;
    RunRemotelyOnClient "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port8080 -- 16";
    RunRemotelyOnClient "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port8080 -- 16";
    RunRemotelyOnClientOutputNoWait "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port8080 -- 16" "$PathofOutput\wrk.log";
    Start-Sleep -s 5;  
    RunRemotelyOnServerOutputNoWait "top -b | head -n 8" "$PathofOutput\top.log";
    Start-Sleep -s 15;
    KillProcess "dotnet";
    KillProcess "top";
}

function RunScenarioKestrel{
   param(
    [string]$TestappName
    )
    if($TestappName -ne "MusicStore")
    {
        $SitePhysicalPath = "~/Performance/testapp/$TestappName/bin/release/netcoreapp1.0/publish";
    }
    else{
        $SitePhysicalPath = "~/musicStore/src/MusicStore/bin/release/netcoreapp1.0/publish";
    }
    Write-Host "Kestrel" + $TestappName -foregroundcolor red -backgroundcolor yellow
    [string]$PathofOutput= $ResultSharePath + "\" + "LinuxKestrel" + $TestappName;
    if(!(Test-Path "$PathofOutput")){
        mkdir "$PathofOutput";
    }

    RunRemotelyOnServerNoWait "$DotnetPath $SitePhysicalPath/$TestappName.dll --server.urls=http://$ServerIP$Port5000";
    Start-Sleep -s 5;
    RunRemotelyOnClient "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port5000 -- 16";
    RunRemotelyOnClient "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port5000 -- 16";
    RunRemotelyOnClientOutputNoWait "wrk -c 256 -t 32 -d 20 -s ~/benchmarks/scripts/pipeline.lua  http://$ServerIP$Port5000 -- 16" "$PathofOutput\wrk.log";
    Start-Sleep -s 10;
    RunRemotelyOnServerOutputNoWait "top -b | head -n 8" "$PathofOutput\top.log";
    Start-Sleep -s 10;
    KillProcess "dotnet";
    KillProcess "top";
}


function BuildBinaries{
    RunRemotelyOnServer 'rpl ''"net451": { }'' '''' ~/Performance/testapp/HelloWorldMvc/project.json -q';
    RunRemotelyOnServer 'rpl ''"net451": { }'' '''' ~/Performance/testapp/BasicKestrel/project.json -q';
    RunRemotelyOnServer 'rpl ''"net451": { }'' '''' ~/musicStore/src/MusicStore/project.json -q';
    
    #Restore and publish
    RunRemotelyOnServer "$DotnetPath restore ~/Performance/testapp/HelloWorldMvc";
    RunRemotelyOnServer "$DotnetPath publish -c release ~/Performance/testapp/HelloWorldMvc";

    RunRemotelyOnServer "$DotnetPath restore ~/Performance/testapp/BasicKestrel";
    RunRemotelyOnServer "$DotnetPath publish -c release ~/Performance/testapp/BasicKestrel";

    RunRemotelyOnServer "$DotnetPath restore ~/musicStore/src/MusicStore";
    RunRemotelyOnServer "$DotnetPath publish -c release ~/musicStore/src/MusicStore";
    
    #Replace SqlServer in config.json
    RunRemotelyOnServer 'rpl ''"ConnectionString": "Server=(localdb)\\MSSQLLocalDB;Database=MusicStore;Trusted_Connection=True;MultipleActiveResultSets=true;Connect Timeout=30;"'' ''"ConnectionString":"Server=aapt-perf-041;Database=MusicStoreHome-Linux;User ID=sa;Password=ASP+Rocks4U;TrustServerCertificate=False;Connection Timeout=30;"'' ~/musicStore/src/MusicStore/bin/release/netcoreapp1.0/publish/config.json -q';
}


Cleanup;
CloneAndBuild;
BuildBinaries;
RunScenarios;
