#!/bin/bash
Date=$(date +%Y-%m-%d)
LogSharePath=~/logshare/Reliability/${Date}
function CleanUp()
{
rm -rf release1.1
rm -rf dev/musicStore
sudo rm -rf ~/.nuget
sudo rm -rf ~/.dotnet
sudo rm -rf ~/.dnx
sudo rm -rf ~/.local
sudo rm -rf /usr/share/dotnet
sudo rm /usr/share/nginx/*.log
sudo rm -rf /tmp/NugetScratch
}

function CloneAndBuild()
{
mkdir -p ~/${1}
cd ~/${1}
git clone https://github.com/aspnet/musicStore/
cd musicStore
sh build.sh
}

function ReplaceDataBase(){
	if [ ${1} = "MusicStoreHome" ] && [ ${2} = "release1.1" ];then
sudo sed -i '12i ""ConnectionString":"Server=tcp:wpt-perf.database.windows.net,1433;Database=musicstore-linuxreliability;User ID=asplab@wpt-perf;Password=iis6!dfu;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" ' config.json
	elif [ ${1} = "MusicStoreE2E" ] && [ ${2} = "release1.1" ];then
sudo sed -i '12i "ConnectionString":"Server=tcp:wpt-perf-scus.database.windows.net,1433;Database=musicstoreE2E-linux;User ID=asplab@wpt-perf-scus;Password=iis6!dfu;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"' config.json
        elif [ ${1} = "MusicStoreHome" ] && [ ${2} = "dev" ];then
sudo sed -i '12i "ConnectionString": "Server=tcp:wpt-perf.database.windows.net,1433;Database=MusicStore-E2E-Kestrel;User ID=asplab@wpt-perf;Password=iis6!dfu;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"' config.json
	else
sudo sed -i '12i "ConnectionString":"Server=tcp:wpt-perf-scus.database.windows.net,1433;Database=musicstoreE2E-linux-kestrel;User ID=asplab@wpt-perf-scus;Password=iis6!dfu;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" ' config.json
        fi
}

function RestoreAndPublish()
{
sudo mkdir -p ${LogSharePath}/Linux${1}${2}
cd ~/${2}/musicStore/src/MusicStore
sudo sed -i 's/"net451": { }/\/\/"net451": {}/g' project.json
sudo sed -i '80a ,"runtimeOptions": {"configProperties": {"System.GC.Server": true}}  ' project.json
sudo sed -i 's/!IsRunningOnWindows || IsRunningOnMono || IsRunningOnNanoServer/false/g' Platform.cs
sudo sed -i '12d' config.json
ReplaceDataBase $1 $2
sudo /home/asplab/.dotnet/dotnet --version > ${LogSharePath}/Linux${1}${2}/version.log 
sudo /home/asplab/.dotnet/dotnet restore --infer-runtimes > ${LogSharePath}/Linux${1}${2}/restore.log 
sudo /home/asplab/.dotnet/dotnet publish -c release > ${LogSharePath}/Linux${1}${2}/publish.log
#cd bin/release/netcoreapp1.0/publish
#sudo /home/asplab/.dotnet/dotnet HelloWorldMvc.dll &> ${LogSharePath}/Linux${1}${2}/Kestrel.log
}

CleanUp

CloneAndBuild $2
RestoreAndPublish $1 $2
