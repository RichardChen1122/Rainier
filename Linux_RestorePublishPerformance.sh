#!/bin/bash
Date=$(date +%Y-%m-%d)
LogSharePath=~/logshare/Reliability/${Date}
function CleanUp()
{
sudo rm -rf ~/release/Performance
sudo rm -rf ~/dev/Performance
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
git clone -b ${1} https://github.com/aspnet/Performance.git
cd Performance
sh build.sh
}

function RestoreAndPublish()
{
sudo mkdir -p ${LogSharePath}/Linux${1}${2}
cd ~/${2}/Performance/testapp/${1}
sudo sed -i 's/"net451"/\/\/"net451"/g' project.json
sudo /home/asplab/.dotnet/dotnet --version > ${LogSharePath}/Linux${1}${2}/version.log 
sudo /home/asplab/.dotnet/dotnet restore --infer-runtimes > ${LogSharePath}/Linux${1}${2}/restore.log 
sudo /home/asplab/.dotnet/dotnet publish -c release > ${LogSharePath}/Linux${1}${2}/publish.log 
#cd bin/release/netcoreapp1.0/publish
#sudo /home/asplab/.dotnet/dotnet HelloWorldMvc.dll &> ${LogSharePath}/Linux${1}${2}/Kestrel.log
}

CleanUp

CloneAndBuild $2
RestoreAndPublish $1 $2
