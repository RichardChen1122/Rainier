$WCAT="$env:ProgramFiles\wcat";
$GitPath = "$env:ProgramFiles\Git";
$RepoPath= "$env:SystemDrive\Repo";

function InstallPreReqs{
#echo $GitPath
    if(!(Test-Path $GitPath))
    {
        Start-Process -FilePath .\Git-2.7.3-64-bit.exe -ArgumentList "/silent /norestart" -NoNewWindow -wait;
    }
    if(!(Test-Path $WCAT))
    {
        $msiexecPath = [System.Environment]::GetFolderPath('System')+"\msiexec.exe";
        Start-Process -FilePath $msiexecPath -ArgumentList "/i wcat.amd64.msi /quiet" -Wait
    }
    if(!(Test-Path $RepoPath)){
        mkdir $RepoPath;
    }    #Add Registey Key    $registryPath ="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters";    New-ItemProperty -Path $registryPath -Name "MaxUserPort" -Value 65534 -PropertyType DWORD -Force | Out-Null;    New-ItemProperty -Path $registryPath -Name "TcpTimedWaitDelay" -Value 30 -PropertyType DWORD -Force | Out-Null;}

InstallPreReqs;


