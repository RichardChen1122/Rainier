$GitPath = "$env:ProgramFiles\Git";
$RepoPath= "$env:SystemDrive\Repo";
$DotnetPath="$env:LOCALAPPDATA\Microsoft\dotnet\";
$RepoRoot = "$RepoPath\Performance";
$date=$(((get-date).ToUniversalTime()).ToString("yyyy-MM-dd"));
$LogSharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare\Build\$date";
$Release="$RepoPath\release1.1";
$Dev="$RepoPath\dev";


function Cleanup{

    if(Test-Path "$RepoPath\Performance\")
    {
        Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clean -xdf" -WorkingDirectory "$RepoPath\Performance\" -NoNewWindow -Wait;
        #rmdir -Recurse -Path $RepoPath\Performance\;
        Remove-Item -Recurse -Force $RepoPath\Performance\
    }
    if(Test-Path "$RepoPath\musicStore\")
    {
        Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clean -xdf" -WorkingDirectory "$RepoPath\musicStore\" -NoNewWindow -Wait;
        #rmdir -Recurse -Path $RepoPath\musicStore\;
        Remove-Item -Recurse -Force $RepoPath\musicStore\
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

function CloneAndBuild{

    param(
    [string]$Branch
    )
    #echo $GitPath
    if(!(Test-Path $Release)){
        mkdir $Release;
    }
    if(!(Test-Path $Dev)){
        mkdir $Dev;
    }

    if(!(Test-Path $LogSharePath)){
        mkdir $LogSharePath;
    }   

    if($Branch -match "release1.1")
    {
        Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clone -b release1.1 https://github.com/aspnet/musicStore" -WorkingDirectory $Release -NoNewWindow -Wait;
        $RepoRoot="$Release\musicStore";
    }
    else
    {
        Start-Process -FilePath "$GitPath\cmd\git.exe" -ArgumentList "clone -b dev https://github.com/aspnet/musicStore" -WorkingDirectory $Dev -NoNewWindow -Wait;
        $RepoRoot="$Dev\musicStore";
    }
   
    cd $RepoRoot;

    cmd /c .\build.cmd;

}

function RestoreAndPublish{
    
    param(
    [string]$Name,
    [string]$Branch
    )

    $BuildSharePath="\\aaptperffs\labshare\AspnetCore\AzFileShare\Build\$Name\$Branch";   
  
    #$WorkDir="$RepoPath\Performance\testapp\$Name";
    $WorkDir="$RepoPath\$Branch\musicStore\src\MusicStore";
    

    if(!(Test-Path "$LogSharePath\$Name\$Branch")){
        mkdir $LogSharePath\$Name\$Branch;
    }

    Start-Process -FilePath "$DotnetPath\dotnet.exe" -ArgumentList "--version" -WorkingDirectory $WorkDir -NoNewWindow -Wait -RedirectStandardOutput "$LogSharePath\$Name\$Branch\version.log";
    Start-Process -FilePath "$DotnetPath\dotnet.exe" -ArgumentList "restore --infer-runtimes" -WorkingDirectory $WorkDir -NoNewWindow -Wait -RedirectStandardOutput "$LogSharePath\$Name\$Branch\restore.log";
    Start-Process -FilePath "$DotnetPath\dotnet.exe" -ArgumentList "publish -c release" -WorkingDirectory $WorkDir -NoNewWindow -Wait -RedirectStandardOutput "$LogSharePath\$Name\$Branch\publish.log";

    cmd /c copy "$WorkDir\project.lock.json" "$LogSharePath\$Name\$Branch"

    if(!(Test-Path "$LogSharePath\$Name\$Branch\net451")){
        mkdir $LogSharePath\$Name\$Branch\net451;
    }
     if(!(Test-Path "$LogSharePath\$Name\$Branch\netcoreapp1.0")){
        mkdir $LogSharePath\$Name\$Branch\netcoreapp1.0;
    }

    cmd /c xcopy /s /i "$WorkDir\bin\release\net451" "$LogSharePath\$Name\$Branch\net451"
    cmd /c xcopy /s /i "$WorkDir\bin\release\netcoreapp1.0" "$LogSharePath\$Name\$Branch\netcoreapp1.0"
   
   

    if(!(Test-Path "$BuildSharePath\net451")){
        #mkdir $BuildSharePath\net451;
    }
    else
    {
        rmdir -Recurse -Path $BuildSharePath\net451\;
    }
    if(!(Test-Path "$BuildSharePath\netcoreapp1.0")){
        #mkdir $BuildSharePath\netcoreapp1.0;
    }
    else
    {
        rmdir -Recurse -Path $BuildSharePath\netcoreapp1.0\;
    }
    
    cmd /c xcopy /s /i "$WorkDir\bin\release\net451" "$BuildSharePath\net451"
    cmd /c xcopy /s /i "$WorkDir\bin\release\netcoreapp1.0" "$BuildSharePath\netcoreapp1.0"
    

}


Cleanup;

CloneAndBuild "release1.1";

RestoreAndPublish "MusicStore" "release1.1";

Cleanup;

CloneAndBuild("dev");

RestoreAndPublish "MusicStore" "dev";

