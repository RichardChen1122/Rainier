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
sudo rm -rf /usr/share/nginx/on
sudo rm -rf ~/jq
}


function CloneAndBuild()
{
cd ~
wget http://stedolan.github.io/jq/download/linux64/jq
chmod 777 ./jq
sudo cp jq /usr/bin
mkdir -p ~/${1}
cd ~/${1}
git clone https://github.com/aspnet/musicStore/
cd musicStore
sh build.sh
}
function ReplaceDataBase(){
length=$(cat ~/Rainier/ConnectionString.json | ~/jq '.Linux | length')
for ((i=0;i<$length;i++))
do
Branch=$(cat ~/Rainier/ConnectionString.json | ~/jq '.Linux['$i'].Branch')
Name=$(cat ~/Rainier/ConnectionString.json | ~/jq '.Linux['$i'].Name')
if [ '"'${1}'"' = $Name ] && [ '"'${2}'"' = $Branch ];then
ConnectionString=$(cat ~/Rainier/ConnectionString.json | ~/jq '.Linux['$i'].ConnectionString')
break
fi
done
Replace='"Server=(localdb)[\][\]MSSQLLocalDB;Database=MusicStore;Trusted_Connection=True;MultipleActiveResultSets=true;Connect Timeout=30;"'
sudo sed -i "s#$Replace#$ConnectionString#g" config.json
}

function RestoreAndPublish()
{
sudo mkdir -p ${LogSharePath}/Linux${1}${2}
cd ~/${2}/musicStore/src/MusicStore
sudo sed -i 's/"net451"/\/\/"net451"/g' project.json
sudo sed -i '80a ,"runtimeOptions": {"configProperties": {"System.GC.Server": true}}  ' project.json
sudo sed -i 's/!IsRunningOnWindows || IsRunningOnMono || IsRunningOnNanoServer/false/g' Platform.cs
ReplaceDataBase $1 $2
sudo /home/asplab/.dotnet/dotnet --version > ${LogSharePath}/Linux${1}${2}/version.log
sudo /home/asplab/.dotnet/dotnet restore --infer-runtimes > ${LogSharePath}/Linux${1}${2}/restore.log
sudo /home/asplab/.dotnet/dotnet publish -c release > ${LogSharePath}/Linux${1}${2}/publish.log
cd bin/release/netcoreapp1.0/publish
sudo /home/asplab/.dotnet/dotnet MusicStore.dll &> ${LogSharePath}/Linux${1}${2}/Kestrel.log
}

CleanUp

CloneAndBuild $2
RestoreAndPublish $1 $2