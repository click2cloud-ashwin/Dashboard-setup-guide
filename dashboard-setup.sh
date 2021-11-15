#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


####################

echo Setup: Enlist Dashboard

cd ~
git clone https://github.com/Click2Cloud-Centaurus/dashboard.git

####################

echo Setup: Export go module

export GO111MODULE=on

####################

echo Setup: Enlisting NVM packages

export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout "git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)"
) && \. "$NVM_DIR/nvm.sh"


echo 'NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                    # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
' >> "$HOME/.bashrc"

source   "$HOME/.profile"

####################

echo Setup: Install NVM packages
nvm install 12
sudo apt install nodejs -y
sudo apt install npm -y
sudo apt install build-essential ruby-full node-typescript -y
npm install --global typescript
npm install --global gulp-cli
npm install --global gulp

####################

cd "$HOME"/dashboard/
if [ "$(whoami)" == "root" ]; then
  npm ci --unsafe-perm
else
  npm ci
fi

####################

# For certificates generations

cd ~ 
mkdir certs
cd certs 
openssl genrsa -out dashboard.key 2048
openssl rsa -in dashboard.key -out dashboard.key
openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj "/CN=$(hostname -i)"
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt

####################

# for service account and set credentials

cd ~
kubectl create namespace kubernetes-dashboard
kubectl create secret generic kubernetes-dashboard-certs --from-file=./certs/dashboard.key --from-file=./certs/dashboard.crt -n kubernetes-dashboard

# Generate a dashboard-admin.yaml file

echo "apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: dashboard-admin
  namespace: kubernetes-dashboard}
" >> "$HOME/dashboard-admin.yaml"

kubectl apply -f dashboard-admin.yaml
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
kubectl describe secrets -n kube-system "$(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')"
sudo ln -snf /var/run/kubernetes/admin.kubeconfig  "$HOME"/.kube/config

echo Setup: Dashboard setup Completed!

####################

