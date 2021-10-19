#!/bin/bash

####################

echo Setup: Enlist Dashboard

cd ~
git clone https://github.com/Click2Cloud-Centaurus/dashboard.git

####################
echo go module

export GO111MODULE=on

####################

echo Enlisting nvm packages

export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
) && \. "$NVM_DIR/nvm.sh"


echo "export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
" >> "~/.bashrc"

source  ~/.profile

####################

echo Installing NVM packages

sudo nvm install 12
sudo apt install nodejs -y
sudo apt install npm -y
sudo apt install build-essential ruby-full node-typescript -y
npm install --global typescript
npm install --global gulp-cli
npm install --global gulp

####################

cd ~/dashboard/
if [ "$(whoami)" == "root" ]; then
  npm ci --unsafe-perm
else
  npm ci
fi


#for certificates
mkdir certs
cd certs
openssl genrsa -out dashboard.key 2048
openssl rsa -in dashboard.key -out dashboard.key
openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj '/CN=IP_OF_VM'
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
#for service account and set credentials
kubectl create namespace kubernetes-dashboard
kubectl create secret generic kubernetes-dashboard-certs --from-file=./certs/dashboard.key --from-file=./certs/dashboard.crt -n kubernetes-dashboard
kubectl create -f dashboard-admin.yaml
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')Extra Dependancies


